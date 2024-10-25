FROM golang:1.22 AS build-env

# Version to build. Default is empty
ARG VERSION
ARG BUILD_TAGS=""
ARG LEDGER_ENABLED="false"
ARG COSMOS_BUILD_OPTIONS=""

WORKDIR /babylon

# Clone the Babylon repo
RUN git clone https://github.com/babylonlabs-io/babylon.git .

# Checkout the correct version
RUN if [ -n "${VERSION}" ]; then \
      git checkout ${VERSION}; \
    fi

# Cache mod dependencies
RUN go mod download

# Build the Babylon binary
RUN LEDGER_ENABLED=$LEDGER_ENABLED \
    BUILD_TAGS=$BUILD_TAGS \
    COSMOS_BUILD_OPTIONS=$COSMOS_BUILD_OPTIONS \
    LINK_STATICALLY=false \
    make build

FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y wget bash curl unzip jq

# Label should match your github repo
LABEL org.opencontainers.image.source="https://github.com/babylonlabs-io/babylond:${VERSION}"

# Install libraries
# Cosmwasm - Download correct libwasmvm version
COPY --from=build-env /babylon/go.mod /tmp
RUN WASMVM_VERSION=$(grep github.com/CosmWasm/wasmvm /tmp/go.mod | cut -d' ' -f2) && \
    wget https://github.com/CosmWasm/wasmvm/releases/download/$WASMVM_VERSION/libwasmvm.$(uname -m).so \
    -O /lib/libwasmvm.$(uname -m).so && \
    # verify checksum
    wget https://github.com/CosmWasm/wasmvm/releases/download/$WASMVM_VERSION/checksums.txt -O /tmp/checksums.txt && \
    sha256sum /lib/libwasmvm.$(uname -m).so | grep $(cat /tmp/checksums.txt | grep libwasmvm.$(uname -m) | cut -d ' ' -f 1)
RUN rm -f /tmp/go.mod

COPY --from=build-env /babylon/build/babylond /bin/babylond

COPY entrypoint.sh /entrypoint.sh
COPY deploy-cw-contract.sh /deploy-cw-contract.sh

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]