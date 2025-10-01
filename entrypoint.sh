#!/bin/bash
set -e

# Load environment variables
if [ -f /app/.env ]; then
  export $(grep -v '^#' /app/.env | xargs)
fi

# Verify GENESIS_URL is set
if [ -z "$GENESIS_URL" ]; then
  echo "❌ GENESIS_URL not set in .env"
  exit 1
fi

# Ensure data directory exists
mkdir -p "$DATA_DIR"

# Download the latest genesis.json
echo "⬇️ Fetching genesis from $GENESIS_URL ..."
curl -s -o /app/genesis.json "$GENESIS_URL"

if [ ! -s /app/genesis.json ]; then
  echo "❌ Failed to fetch genesis.json from $GENESIS_URL"
  exit 1
fi

# Initialize only if not already initialized
if [ ! -d "$DATA_DIR/geth" ]; then
  echo "🔄 Initializing geth with genesis.json ..."
  geth init --datadir "$DATA_DIR" /app/genesis.json
else
  echo "✅ Geth already initialized, skipping init"
fi

# Start the Ethereum node
echo "🚀 Starting Geth node..."
exec geth \
  --datadir "$DATA_DIR" \
  --networkid "$CHAIN_ID" \
  --http \
  --http.addr "$HOST" \
  --http.port "$RPC_PORT" \
  --http.api "eth,net,web3,personal,miner" \
  --http.corsdomain="*" \
  --http.vhosts="*" \
  --allow-insecure-unlock \
  --unlock 0 \
  --password "$SIGNER_PASSWORD" \
  --mine \
  --miner.etherbase 0 \
  --nodiscover \
  --verbosity 3
