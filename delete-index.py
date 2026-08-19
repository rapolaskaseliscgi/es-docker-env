import argparse
import logging
import re
import sys
from datetime import date

import requests

REMOTE_URL = "http://localhost:9200"

INDICES_PATH = "/_cat/indices"
FT_INDEX_PATTERN = re.compile(r"(ft_.+)-(\d{6})")
EMPTY_NFD_INDEX_PATTERN = re.compile(
    r"(?:nfd-\d+|no_fault_divorce_bulkaction-\d+)_cases-000001"
)

logger = logging.getLogger(__name__)


def parse_args():
    parser = argparse.ArgumentParser(
        description="List obsolete or empty Elasticsearch indices."
    )
    parser.add_argument(
        "--delete",
        action="store_true",
        help="Actually delete the listed indices (the default is a dry run).",
    )
    return parser.parse_args()


def configure_logging():
    log_file = f"deleted-indices-{date.today().isoformat()}.log"
    logging.basicConfig(
        level=logging.INFO,
        format="%(asctime)s %(levelname)s %(message)s",
        handlers=[
            logging.FileHandler(log_file, encoding="utf-8"),
            logging.StreamHandler(sys.stdout),
        ],
    )


def read_indices_from_remote():
    query_params = {
        "s": "index",
        "format": "json",
        "h": "index,docs.count",
    }
    response = requests.get(f"{REMOTE_URL}{INDICES_PATH}", params=query_params)

    if response.status_code != 200:
        logger.error(
            "Failed to fetch indices from remote. Status code: %s, Response: %s",
            response.status_code,
            response.text,
        )
        return []

    return response.json()


def get_indices_to_delete(indices=None):
    if indices is None:
        indices = read_indices_from_remote()

    indices_by_name = {}
    empty_nfd_indices = []
    for index_info in indices:
        index_name = index_info["index"]
        docs_count = index_info.get("docs.count")

        if (
            docs_count is not None
            and str(docs_count) == "0"
            and EMPTY_NFD_INDEX_PATTERN.fullmatch(index_name)
        ):
            empty_nfd_indices.append(index_name)

        match = FT_INDEX_PATTERN.fullmatch(index_name)
        if not match:
            continue

        index_family, version = match.groups()
        indices_by_name.setdefault(index_family, []).append(
            (int(version), index_name)
        )

    indices_to_delete = []
    for versioned_indices in indices_by_name.values():
        latest_version = max(version for version, _ in versioned_indices)
        indices_to_delete.extend(
            index_name
            for version, index_name in versioned_indices
            if version != latest_version
        )

    indices_to_delete.extend(empty_nfd_indices)
    return sorted(indices_to_delete)


def delete_indices(should_delete=False):
    indices = get_indices_to_delete()
    for index in indices:
        if not should_delete:
            logger.info("Deletable index: %s", index)
            continue

        logger.info("Deleting index: %s", index)
        response = requests.delete(f"{REMOTE_URL}/{index}")
        if response.status_code == 200:
            logger.info("Successfully deleted index: %s", index)
        elif response.status_code == 404:
            logger.warning("Index not found (already deleted?): %s", index)
        else:
            logger.error(
                "Failed to delete index: %s. Status code: %s, Response: %s",
                index,
                response.status_code,
                response.text,
            )


if __name__ == "__main__":
    args = parse_args()
    configure_logging()
    delete_indices(should_delete=args.delete)
