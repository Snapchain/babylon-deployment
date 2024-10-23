#!/bin/bash
privateKey=/snapchainKey
echo "12345678" > input.data
babylond keys import $key $privateKey $keyringBackend < input.data