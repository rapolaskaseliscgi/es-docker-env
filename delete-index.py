import requests

REMOTE_URL="http://localhost:9200"

def get_indices_to_delete():
    with open("indices_to_delete.txt", "r") as file:
        indices = file.readlines()
    return indices


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