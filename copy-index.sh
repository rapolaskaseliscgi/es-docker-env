#!/bin/bash

DEMO_URL="http://localhost:10200"
LOCAL_URL="http://localhost:9200"
INDEX="$1"

if [ -z "$INDEX" ]; then
  echo "Usage: $1 <index-name>  # eg bail_cases-000001", requires tunnel from demo environment running on port 10200
  exit 1
fi

echo "Fetching settings, mappings, and aliases for $INDEX..."

curl -s "$DEMO_URL/$INDEX/_settings" > settings.json
curl -s "$DEMO_URL/$INDEX/_mapping" > mapping.json
curl -s "$DEMO_URL/$INDEX/_alias" > alias.json


echo "Cleaning settings..."

jq ".[\"$INDEX\"].settings | del(.index.uuid, .index.version, .index.provided_name, .index.creation_date)" settings.json > clean-settings.json

echo "Cleaning mappings..."

jq ".[\"$INDEX\"].mappings" mapping.json > clean-mapping.json

echo "Building create-index.json..."

jq -s '{ settings: .[0], mappings: .[1] }' clean-settings.json clean-mapping.json > create-index.json

echo "Building alias-actions.json..."
# alias.json shape: { "index": { "aliases": { "alias": { ... } } } }
jq -c --arg idx "$INDEX" '
  .[$idx].aliases
  | to_entries
  | map({ add: ({ index: $idx, alias: .key } + (.value // {})) })
  | { actions: . }
' alias.json > alias-actions.json


echo "Deleting local index if exists..."
curl -s -XDELETE "$LOCAL_URL/$INDEX"
echo;

echo "Creating local index from cleaned mapping & settings..."
curl -s -XPUT "$LOCAL_URL/$INDEX" \
  -H "Content-Type: application/json" \
  --data-binary @create-index.json


echo;
echo "Applying aliases on local cluster (if any)..."
# Only apply if there are actions (non-empty array)
if [ "$(jq -r '.actions | length' alias-actions.json)" -gt 0 ]; then
  curl -s -XPOST "$LOCAL_URL/_aliases" \
    -H "Content-Type: application/json" \
    --data-binary @alias-actions.json | jq
else
  echo "No aliases found for $INDEX"
fi

echo "Done! Local index created: $INDEX"


echo "Fetching some documents...";
curl -s "${DEMO_URL}/${INDEX}/_search?size=5000" | jq -c '.hits.hits[] | {id: ._id, source: ._source}' > docs.jsonl;

echo "Uploading to local index...";

while read line; do
  id=$(echo "$line" | jq -r '.id')
  src=$(echo "$line" | jq -c '.source')
  echo "${id}"
  curl -s -XPUT "${LOCAL_URL}/${INDEX}/_doc/$id" \
    -H "Content-Type: application/json" \
    -d "$src" > /dev/null
done < docs.jsonl;

echo "Cleaninig up..."

rm -f create-index.json \
      clean-settings.json \
      clean-mapping.json \
      settings.json \
      mapping.json \
      alias.json \
      alias-actions.json \
      docs.jsonl

exit 0;