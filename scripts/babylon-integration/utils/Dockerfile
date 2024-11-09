FROM debian:bookworm-slim

ARG BABYLOND_VERSION="euphrates-0.5.0-rc.0"
ARG BABYLOND_FILE="babylond-linux-amd64"

RUN apt-get update && apt-get install -y bash wget curl unzip jq

# Download the babylond binary
RUN echo "Downloading babylond with the version $BABYLOND_VERSION..."
RUN curl -SL "https://github.com/Snapchain/babylond/releases/download/$BABYLOND_VERSION/${BABYLOND_FILE}" -o "${BABYLOND_FILE}"
RUN mv ${BABYLOND_FILE} /bin/babylond
RUN chmod +x /bin/babylond

# Install libraries
# Cosmwasm - Download correct libwasmvm version
RUN curl -SL "https://raw.githubusercontent.com/babylonlabs-io/babylon/refs/tags/$BABYLOND_VERSION/go.mod" -o /tmp/go.mod
RUN WASMVM_VERSION=$(grep github.com/CosmWasm/wasmvm /tmp/go.mod | cut -d' ' -f2) && \
    wget https://github.com/CosmWasm/wasmvm/releases/download/$WASMVM_VERSION/libwasmvm.$(uname -m).so \
    -O /lib/libwasmvm.$(uname -m).so && \
    # verify checksum
    wget https://github.com/CosmWasm/wasmvm/releases/download/$WASMVM_VERSION/checksums.txt -O /tmp/checksums.txt && \
    sha256sum /lib/libwasmvm.$(uname -m).so | grep $(cat /tmp/checksums.txt | grep libwasmvm.$(uname -m) | cut -d ' ' -f 1)
RUN rm -f /tmp/go.mod

COPY set-babylon-keys.sh /set-babylon-keys.sh
COPY register-consumer-chain.sh /register-consumer-chain.sh
COPY common.sh /common.sh
COPY deploy-cw-contract.sh /deploy-cw-contract.sh
COPY toggle-cw-killswitch.sh /toggle-cw-killswitch.sh
COPY teardown.sh /teardown.sh