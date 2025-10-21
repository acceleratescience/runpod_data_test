#!/bin/bash
set -e

apt-get update -y
apt-get install -y --no-install-recommends git python3-pip ca-certificates
rm -rf /var/lib/apt/lists/*

if [ -d /workspace/workshop/.git ]; then
  echo "Repository already exists at /workspace/workshop — skipping clone."
else
  git clone https://github.com/acceleratescience/diffusion-models.git /workspace/workshop
  echo "Repository cloned to /workspace/workshop"
fi

cd /workspace/workshop

# Remove unneeded files
rm -rf .github docs overrides .dockerignore .pre-commit-config.yaml mkdocs.yml
echo "Removed extra files."

# Install dependencies using uv
pip install uv
uv sync

# Extras
pip install torch torchvision
