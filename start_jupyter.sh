#!/bin/bash
set -e

# --- Install dependencies ---
apt-get update -y
apt-get install -y --no-install-recommends ca-certificates python3-pip
rm -rf /var/lib/apt/lists/*

# --- Install JupyterLab ---
pip install --upgrade pip jupyterlab notebook

# --- Start JupyterLab in /workspace/workshop ---
cd /workspace/workshop
nohup jupyter lab \
  --ip=0.0.0.0 \
  --port=8888 \
  --no-browser \
  --allow-root \
  --NotebookApp.token='' \
  --NotebookApp.password='' \
  --ServerApp.token='' \
  --ServerApp.password='' \
  --ServerApp.base_url=/ \
  --ServerApp.trust_xheaders=True \
  --ServerApp.use_redirect_file=False \
  --ServerApp.allow_origin='*' \
  --ServerApp.allow_origin_pat='.*proxy\.runpod\.net' \
  --ServerApp.disable_check_xsrf=True \
  --ServerApp.root_dir=/workspace/workshop \
  >/tmp/jupyter.log 2>&1 &

echo "JupyterLab started on port 8888. Logs: /tmp/jupyter.log"
