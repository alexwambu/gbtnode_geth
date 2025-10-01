#!/bin/bash
set -e

# Load environment variables from .env if it exists
if [ -f /app/.env ]; then
  export $(grep -v '^#' /app/.env | xargs)
fi

# Fallback for GENESIS_URL if not set
: "${GENESIS_URL:=https://genesis-sever-node.onrender.com/genesis}"
: "${DATA_DIR:=/app/data}"
: "${CHAIN_ID:=999}"
: "${HOST:=0.0.0.0}"
: "${RPC_PORT:=9636}"
: "${SIGNER_KEY:=/app/signer.key}"
: "${SIGNER_PASSWORD:=/app/password.txt}"

echo "===> Using Genesis URL: $GENESIS_URL"

# Create data directory if not exists
mkdir -p "$DATA_DIR"

# Download genesis.json from server
echo "===> Fetching genesis.json ..."
curl -s -o "$DATA_DIR/genesis.json" "$GENESIS_URL"

if [ ! -s "$DATA_DIR/genesis.json" ]; then
  echo "ERROR: Failed to fetch genesis.json from $GENESIS_URL"
  exit 1
fi

# Initialize the chain with genesis.json
if [ ! -d "$DATA_DIR/geth" ]; then
  echo "===> Initializing new chain with genesis.json"
  geth --datadir "$DATA_DIR" init "$DATA_DIR/genesis.json"
fi

# Start geth with RPC enabled
echo "===> Starting Geth Node..."
exec geth \
  --datadir "$DATA_DIR" \
  --networkid "$CHAIN_ID" \
  --http --http.addr "$HOST" --http.port "$RPC_PORT" --http.api "eth,net,web3,personal" \
  --allow-insecure-unlock \
  --unlock 0 \
  --password "$SIGNER_PASSWORD" \
  --mine --miner.etherbase=0x0000000000000000000000000000000000000000
