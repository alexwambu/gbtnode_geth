#!/bin/sh
set -e

# Load env vars
: "${GENESIS_SERVER_URL:?GENESIS_SERVER_URL not set}"
: "${CHAIN_ID:=999}"
: "${SIGNER:?SIGNER address not set}"

echo "Requesting genesis.json from server: $GENESIS_SERVER_URL"
curl -sSL -X POST $GENESIS_SERVER_URL/genesis \
  -H "Content-Type: application/json" \
  -d "{\"chainId\": $CHAIN_ID, \"signer\": \"$SIGNER\"}" \
  -o /app/genesis.json

if [ ! -s /app/genesis.json ]; then
  echo "❌ Failed to fetch genesis.json from server"
  exit 1
fi

# Initialize chain
geth --datadir /app/data init /app/genesis.json

# Start Geth in background
geth \
  --datadir /app/data \
  --networkid $CHAIN_ID \
  --http --http.addr 0.0.0.0 --http.port 9636 \
  --http.api eth,net,web3,personal \
  --http.corsdomain "*" \
  --allow-insecure-unlock \
  --nodiscover \
  --port 30303 &
GETH_PID=$!

# Start health server in background
python3 /app/health_server.py &
HEALTH_PID=$!

# Keepalive: check Geth every 18s
while true; do
  if ! kill -0 $GETH_PID 2>/dev/null; then
    echo "❌ Geth process exited, shutting down..."
    kill $HEALTH_PID || true
    exit 1
  fi
  echo "✅ Geth running (PID $GETH_PID)"
  sleep 18
done
