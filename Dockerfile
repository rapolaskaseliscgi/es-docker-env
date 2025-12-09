FROM ubuntu:24.04

ENV container=docker

RUN apt-get update && \
    apt-get install -y vim systemd systemd-sysv apt-transport-https wget gnupg curl sudo less

# Install Elasticsearch via DEB package
RUN wget https://artifacts.elastic.co/downloads/elasticsearch/elasticsearch-7.17.29-arm64.deb && \
    dpkg -i elasticsearch-7.17.29-arm64.deb || apt-get install -f -y && \
    rm elasticsearch-7.17.29-arm64.deb && \
    systemctl enable elasticsearch.service

RUN mkdir -p /etc/elasticsearch/jvm.options.d && \
    printf "%s\n" \
      "-Xms256m" \
      "-Xmx256m" \
      "-Des.cgroups.hierarchy.override=/" \
    > /etc/elasticsearch/jvm.options.d/docker-arm.options

# Ensure directories exist for data and config
RUN mkdir -p /var/lib/elasticsearch && \
    mkdir -p /etc/elasticsearch

COPY elasticsearch.yml /elasticsearch.yml.template

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
# Required for systemd services inside Docker
VOLUME [ "/sys/fs/cgroup" ]

CMD ["/entrypoint.sh"]