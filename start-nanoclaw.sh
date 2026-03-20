#!/bin/bash
# start-nanoclaw.sh — Start NanoClaw without systemd
# To stop: kill \$(cat /Users/arco/nanoclaw-sandbox-7814/nanoclaw.pid)

set -euo pipefail

cd "/Users/arco/nanoclaw-sandbox-7814"

# Stop existing instance if running
if [ -f "/Users/arco/nanoclaw-sandbox-7814/nanoclaw.pid" ]; then
  OLD_PID=$(cat "/Users/arco/nanoclaw-sandbox-7814/nanoclaw.pid" 2>/dev/null || echo "")
  if [ -n "$OLD_PID" ] && kill -0 "$OLD_PID" 2>/dev/null; then
    echo "Stopping existing NanoClaw (PID $OLD_PID)..."
    kill "$OLD_PID" 2>/dev/null || true
    sleep 2
  fi
fi

# Start proxy relay for nested Docker containers (Docker-in-Docker)
if [ -n "${PROXY_RELAY_PORT:-}" ] && [ -n "${HTTPS_PROXY:-}" ]; then
  pkill -f "socat.*${PROXY_RELAY_PORT}" 2>/dev/null || true
  nohup socat TCP-LISTEN:${PROXY_RELAY_PORT},bind=172.17.0.1,fork,reuseaddr TCP:host.docker.internal:3128 > /dev/null 2>&1 &
  echo "Proxy relay started on 172.17.0.1:${PROXY_RELAY_PORT}"
fi

echo "Starting NanoClaw..."
nohup "/usr/bin/node" "/Users/arco/nanoclaw-sandbox-7814/dist/index.js" \
  >> "/Users/arco/nanoclaw-sandbox-7814/logs/nanoclaw.log" \
  2>> "/Users/arco/nanoclaw-sandbox-7814/logs/nanoclaw.error.log" &

echo $! > "/Users/arco/nanoclaw-sandbox-7814/nanoclaw.pid"
echo "NanoClaw started (PID $!)"
echo "Logs: tail -f /Users/arco/nanoclaw-sandbox-7814/logs/nanoclaw.log"
