#!/bin/bash
set -e

### CONFIG
SOURCE_OWNER="acceleratescience"
SOURCE_REPO="hands-on-llms"
BRANCH="main"
###

WORKDIR="/workspace/workshop"
TOKEN_FILE="$WORKDIR/github_token.txt"

apt-get update -y
apt-get install -y --no-install-recommends git python3-pip ca-certificates jq
rm -rf /var/lib/apt/lists/*

if [ -d "$WORKDIR/.git" ]; then
  echo "Repository already exists at $WORKDIR — skipping clone."
else
  git clone -b $BRANCH https://github.com/$SOURCE_OWNER/$SOURCE_REPO.git "$WORKDIR"
  echo "Repository cloned to $WORKDIR"
fi

cd "$WORKDIR"

rm -rf .github docs overrides .devcontainer .dockerignore .pre-commit-config.yaml mkdocs.yml
echo "Removed extra files."

pip install uv
uv sync