FROM debian:bullseye-slim

RUN useradd --system --user-group bitcoin \
  && apt-get update -y \
  && apt-get install -y curl gnupg gosu jq \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ARG BITCOIN_CORE_VERSION="26.0"
ENV BITCOIN_CORE_VERSION=$BITCOIN_CORE_VERSION
ENV PATH=/opt/bitcoin-${BITCOIN_CORE_VERSION}/bin:$PATH

RUN set -ex \
  && curl -SLO https://bitcoincore.org/bin/bitcoin-core-${BITCOIN_CORE_VERSION}/bitcoin-${BITCOIN_CORE_VERSION}-x86_64-linux-gnu.tar.gz \
  && tar -xzf *.tar.gz -C /opt

WORKDIR /bitcoind

ENTRYPOINT ["bitcoind"]