import requests

REMOTE_URL="http://localhost:10200"

indices = [
"ft_caseaccess_1role_cases-000001",
"ft_caseaccess_2roles_cases-000001",
]

for index in indices:
    print(f"Deleting index: {index}")
    response = requests.delete(f"{REMOTE_URL}/{index}")
    if response.status_code == 200:
        print(f"Successfully deleted index: {index}")
    elif response.status_code == 404:
        print(f"Index not found (already deleted?): {index}")
    else:
        print(f"Failed to delete index: {index}. Status code: {response.status_code}, Response: {response.text}")
