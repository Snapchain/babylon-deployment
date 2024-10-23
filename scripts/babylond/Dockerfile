FROM debian:bullseye-slim

RUN apt-get update -y \
  && apt-get install -y curl zip git jq build-essential \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* 

RUN curl -SLO https://go.dev/dl/go1.22.7.linux-amd64.tar.gz \
  && rm -rf /usr/local/go \
  && tar -C /usr/local -xzf go1.22.7.linux-amd64.tar.gz \
  && export PATH=$PATH:/usr/local/go/bin

ENV PATH=$PATH:/usr/local/go/bin:/root/go/bin

WORKDIR /babylond

COPY entrypoint.sh /entrypoint.sh
COPY env_euphrates.sh /env_euphrates.sh
COPY snapchainKey.example /snapchainKey
COPY import_key.sh /import_key.sh
COPY init.sh /root/init.sh

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]