#!/bin/bash
set -e

apt-get update -y
apt-get install -y --no-install-recommends git python3-pip ca-certificates
rm -rf /var/lib/apt/lists/*

if [ -d /workspace/workshop/.git ]; then
  echo "Repository already exists at /workspace/workshop — skipping clone."
else
  git clone https://github.com/acceleratescience/packaging-publishing.git /workspace/workshop
  echo "Repository cloned to /workspace/workshop"
fi

cd /workspace/workshop

rm -rf .github docs overrides .devcontainer .dockerignore .pre-commit-config.yaml mkdocs.yml
echo "Removed extra files."

pip install uv
uv sync