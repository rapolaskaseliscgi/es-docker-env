
import json
import requests
import sys
import time


REMOTE_URL="http://localhost:10200"
LOCAL_URL="http://localhost:9200"

BATCH_SIZE = 20
SCROLL_TTL = "1m"
MAX_RETRIES = 5
BACKOFF_BASE_SECONDS = 5


if len(sys.argv) != 2:
    print("Usage: python copy-index.py <index-name> # eg. bail_cases-000001")
    sys.exit(1)


def _request_with_retry(method, url, **kwargs):
    for attempt in range(MAX_RETRIES):
        try:
            resp = requests.request(method, url, **kwargs)

            # Retry on Too Many Requests
            if resp.status_code == 429:
                retry_after = resp.headers.get("Retry-After")
                if retry_after is not None:
                    try:
                        delay = float(retry_after)
                    except ValueError:
                        delay = BACKOFF_BASE_SECONDS * (2 ** attempt)
                else:
                    delay = BACKOFF_BASE_SECONDS * (2 ** attempt)
                print(f"429 from {url}. Backing off for {delay:.2f}s (attempt {attempt+1}/{MAX_RETRIES}).")
                time.sleep(delay)
                continue

            return resp
        except (requests.exceptions.ConnectionError, requests.exceptions.Timeout) as e:
            if attempt >= MAX_RETRIES:
                raise
            delay = BACKOFF_BASE_SECONDS * (2 ** attempt)
            print(f"Transient error calling {url}: {e}. Retrying in {delay:.2f}s (attempt {attempt + 1}/{MAX_RETRIES}).")
            time.sleep(delay)

    raise RuntimeError(f"Failed to call {url} after {MAX_RETRIES} retries")


def generic_es_command(method, url, **kwargs):
    response = requests.request(method, url, **kwargs)
    response.raise_for_status()
    return response


def clean_settings(settings):
    # Remove settings that should not be copied
    settings_to_remove = [
        'creation_date',
        'uuid',
        'version',
        'provided_name'
    ]
    for setting in settings_to_remove:
        if setting in settings:
            del settings[setting]
    return settings


def get_index_settings(index_name):
    response = requests.get(f"{REMOTE_URL}/{index_name}/_settings")
    response.raise_for_status()
    settings = response.json()
    index_settings = settings[index_name]['settings']['index']
    cleaned_settings = clean_settings(index_settings)
    return {"index": cleaned_settings}


def get_index_mapping(index_name):
    response = requests.get(f"{REMOTE_URL}/{index_name}/_mapping")
    response.raise_for_status()
    mapping = response.json()
    return mapping[index_name]['mappings']


def get_index_aliases(index_name):
    response = requests.get(f"{REMOTE_URL}/{index_name}/_alias")
    if response.status_code == 404:
        return {}
    response.raise_for_status()
    aliases = response.json()
    return aliases[index_name].get('aliases', {})


def delete_index(index_name):
    response = requests.delete(f"{LOCAL_URL}/{index_name}")
    if response.status_code == 200:
        print(f"Deleted existing index {index_name} on local server.")
    elif response.status_code == 404:
        print(f"No existing index {index_name} to delete on local server.")
    else:
        print(f"Failed to delete index {index_name} on local server: {response.text}")


def create_index(index_name, settings, mappings, aliases):
    create_index_payload = {
        "settings": settings,
        "mappings": mappings
    }
    if aliases:
        create_index_payload["aliases"] = aliases

    response = requests.put(f"{LOCAL_URL}/{index_name}", json=create_index_payload)
    if response.status_code < 400:
        print(f"Created index {index_name} on local server.")
    else:
        print(f"Failed to create index {index_name} on local server: {response.text}")
    response.raise_for_status()


def _build_bulk_ndjson(index_name, hits):
    lines = []
    for hit in hits:
        meta = {"index": {"_index": index_name, "_id": hit.get("_id")}}
        lines.append(json.dumps(meta))
        lines.append(json.dumps(hit.get("_source", {})))
    return "\n".join(lines) + "\n"


def _bulk_index_batch(index_name, hits):
    if not hits:
        return 0
    ndjson = _build_bulk_ndjson(index_name, hits)
    response = _request_with_retry(
        "POST",
        f"{LOCAL_URL}/_bulk",
        data=ndjson,
        headers={"Content-Type": "application/x-ndjson"},
        params={"refresh": "false"}
    )
    response.raise_for_status()

    payload = response.json()
    if payload.get("errors"):
        first_error = None
        for item in payload.get("items", []):
            op = item.get("index") or item.get("create") or item.get("update") or item.get("delete")
            if op and op.get("error"):
                first_error = op.get("error")
                break
        raise Exception(f"Bulk indexing error: {first_error}")
    return len(hits)


def copy_documents(index_name, query=None):
    settings = {"index": {"number_of_replicas": 0, "refresh_interval": "-1"}}
    generic_es_command("PUT", f"{LOCAL_URL}/{index_name}/_settings", json=settings)

    batch_size = BATCH_SIZE
    scroll_ttl = SCROLL_TTL
    query = query or {"match_all": {}}

    search_body = {"query": query, "sort": ["_doc"]}
    response = requests.post(
        f"{REMOTE_URL}/{index_name}/_search",
        params = {"scroll": scroll_ttl, "size": batch_size},
        json=search_body
    )
    response.raise_for_status()
    data = response.json()
    scroll_id = data.get('_scroll_id')
    if not scroll_id:
        print("No scroll ID returned from initial search.")
        return
    total_copied = 0


    while True:
        hits = data.get('hits', {}).get('hits', [])
        if not hits:
            break

        # Bulk index this scroll page (sequentially)
        total_copied += _bulk_index_batch(index_name, hits)
        print(f"Progress: {total_copied} documents copied...")

        scroll_response = _request_with_retry(
            "POST",
            f"{REMOTE_URL}/_search/scroll",
            json = {"scroll": scroll_ttl, "scroll_id": scroll_id}
        )
        scroll_response.raise_for_status()
        data = scroll_response.json()
        scroll_id = data.get('_scroll_id', scroll_id)

    try:
        requests.delete(f"{REMOTE_URL}/_search/scroll", json={"scroll_id": [scroll_id]})
    except Exception as e:
        print(f"Failed to clear scroll ID {scroll_id}: {e}")

    settings = {"index": {"number_of_replicas": 1, "refresh_interval": "1s"}}
    generic_es_command("PUT", f"{LOCAL_URL}/{index_name}/_settings", json=settings)

    requests.post(f"{LOCAL_URL}/{index_name}/_refresh")

    print(f"Completed copying documents. Total documents copied: {total_copied}")


def main(index_name):
    # hardcoded so I don't need to type it
    # index_name = "bail_cases-000001"

    settings = get_index_settings(index_name)
    mappings = get_index_mapping(index_name)
    aliases = get_index_aliases(index_name)
    delete_index(index_name)
    create_index(index_name, settings, mappings, aliases)
    copy_documents(index_name)


if __name__ == "__main__":
    main(sys.argv[1])
    sys.exit(0)
