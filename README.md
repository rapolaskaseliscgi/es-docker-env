## Elasticsearch cluster in docker

Install and run elasticsearch V7 on docker environment

### Steps to run:
1. build docker image:

```zsh
  docker build . -t ubuntu-systemd:latest
```

2. run docker compose:

```zsh
  docker compose up --build
```
This should give a running green cluster of two nodes

Optional to copy some data:

3. Setup ssh tunnel to demo environment to expose elasticsearch on port 10200

```zsh
ssh -L 10200:ccd-elastic-search-demo.service.core-compute-demo.internal:9200 bastion-nonprod.platform.hmcts.net
```

4. Copy some elasticsearch data from demo (bail_cases-000001 is index to copy):

```zsh
  ./copy-index.sh bail_cases-000001
```

### To restart from scratch
1. Stop docker compose

2. Run clean environment script:

```zsh
  ./cleanup-env.sh
```
3. Repeat steps on "Steps to run"

### register directory for data snapshots

```
curl -sS -X PUT "http://localhost:9200/_snapshot/my_fs_repo" -H 'Content-Type: application/json' -d'
{
  "type": "fs",
  "settings": {
    "location": "/usr/share/elasticsearch/backup",
    "compress": true
  }
}
'
```

Take snapshot:

curl -sS -X PUT "http://localhost:9200/_snapshot/my_fs_repo/snap_2026_03_10?wait_for_completion=true"

List snapshots:

curl -sS "http://localhost:9200/_cat/snapshots/my_fs_repo?v&s=start_epoch:desc"

restore from snapshot:

curl -sS -X POST "http://localhost:9200/_snapshot/my_fs_repo/snap_2026_03_10_9-indices/_restore" -H 'Content-Type: application/json' -d'{"include_global_state": true}'