#!/bin/sh
set -e

echo "Installing tools..."
apk update >/dev/null
apk add --no-cache curl jq netcat-openbsd >/dev/null

echo "Waiting for ES01 TCP port..."
until nc -z es01 9200; do sleep 1; done

echo "Waiting for ES01 cluster health..."
until curl -s http://es01:9200/_cluster/health \
  | jq -e '.status=="yellow" or .status=="green"' >/dev/null 2>&1; do sleep 1; done

echo "ES01 is up — applying watermarks..."
curl -XPUT http://es01:9200/_cluster/settings \
  -H "Content-Type: application/json" \
  -d '{
        "persistent": {
          "cluster.routing.allocation.disk.watermark.low":  "99%",
          "cluster.routing.allocation.disk.watermark.high": "99%",
          "cluster.routing.allocation.disk.watermark.flood_stage": "99%"
        }
      }'

echo "Watermarks applied successfully!"