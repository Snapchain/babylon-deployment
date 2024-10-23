#!/bin/bash
set -euo pipefail

cd /
. ./env_euphrates.sh
echo "Starting babylond..."

./import_key.sh
echo "import key done"

cd $HOME
./init.sh
echo "init done"


