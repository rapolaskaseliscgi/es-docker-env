#!/bin/bash
set -e

docker rm es01 es02
docker volume rm \
  es-upgrade_es01_conf \
  es-upgrade_es01_data \
  es-upgrade_es02_conf \
  es-upgrade_es02_data
