import re

import requests

REMOTE_URL="http://localhost:9200"

INDICES_TO_DELETE_FILE = "indices-to-delete.txt"

def read_indices_from_file(file_path):
    with open(file_path, "r") as file:
        return [line.strip() for line in file if line.strip()]


def get_indices_to_delete():
    indices_from_file = read_indices_from_file(INDICES_TO_DELETE_FILE)

    indices_by_name = {}
    for line in indices_from_file:

        index_name = line.split()[0]
        match = re.fullmatch(r"(.+)-(\d{6})", index_name)
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

    return indices_to_delete


def delete_indices():
    indices = get_indices_to_delete()
    for index in indices:
        print(f"Deleting index: {index}")
        response = requests.delete(f"{REMOTE_URL}/{index.strip()}")
        if response.status_code == 200:
            print(f"Successfully deleted index: {index}")
        elif response.status_code == 404:
            print(f"Index not found (already deleted?): {index}")
        else:
            print(f"Failed to delete index: {index}. Status code: {response.status_code}, Response: {response.text}")


if __name__ == "__main__":
    delete_indices()
