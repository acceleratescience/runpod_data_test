#!/bin/bash
set -e

apt-get update -y
apt-get install -y --no-install-recommends git ca-certificates
rm -rf /var/lib/apt/lists/*

if [ -d /workspace/workshop/.git ]; then
  echo "Repository already exists at /workspace/workshop — skipping clone."
else
  git clone https://github.com/acceleratescience/diffusion-models.git /workspace/workshop
  echo "Repository cloned to /workspace/workshop"
fi
