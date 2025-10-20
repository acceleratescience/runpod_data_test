#!/bin/bash
set -e

# --- Install dependencies ---
apt-get update -y
apt-get install -y --no-install-recommends curl ca-certificates
rm -rf /var/lib/apt/lists/*

# --- Install code-server ---
curl -fsSL https://code-server.dev/install.sh | sh

# --- Start code-server in /workspace/runpod_data_test/data ---
cd /workspace/runpod_data_test/data
nohup /usr/bin/code-server \
  --bind-addr 0.0.0.0:8080 \
  --auth none \
  >/tmp/code.log 2>&1 &

echo "code-server started on port 8080. Logs: /tmp/code.log"
