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

3. Setup ssh tunnel to demo environment to expose elasticsearch on port 10200
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