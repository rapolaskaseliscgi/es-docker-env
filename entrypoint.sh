#!/bin/bash
set -e

# Ensure perms
chown -R elasticsearch:elasticsearch /var/lib/elasticsearch

# Insert the node name dynamically
sed "s/{{NODE_NAME}}/$NODE_NAME/" /elasticsearch.yml.template \
    > /etc/elasticsearch/elasticsearch.yml

# Start systemd
exec /sbin/init