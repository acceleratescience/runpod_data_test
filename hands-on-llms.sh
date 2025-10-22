#!/bin/bash
set -e

### CONFIG
SOURCE_OWNER="acceleratescience"
SOURCE_REPO="hands-on-llms"
BRANCH="main"
WORKDIR="/workspace/workshop"
TOKEN_FILE="$WORKDIR/github_token.txt"
###

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

# --- GitHub auto-commit system ---
touch "$TOKEN_FILE"
echo "Monitoring for a GitHub token in $TOKEN_FILE..."

while true; do
  if [ ! -s "$TOKEN_FILE" ]; then
    echo "No token found yet — waiting 5 minutes..."
    sleep 300
    continue
  fi

  TOKEN=$(cat "$TOKEN_FILE")
  USERNAME=$(curl -s -H "Authorization: token $TOKEN" https://api.github.com/user | jq -r .login)

  if [ -z "$USERNAME" ] || [ "$USERNAME" == "null" ]; then
    echo "Invalid or expired GitHub token — waiting 5 minutes..."
    sleep 300
    continue
  fi

  echo "Valid token detected for $USERNAME — proceeding with fork and auto-commit setup."
  DEST_REPO="https://$USERNAME:$TOKEN@github.com/$USERNAME/$SOURCE_REPO.git"

  echo "Forking $SOURCE_OWNER/$SOURCE_REPO to $USERNAME..."
  curl -s -X POST -H "Authorization: token $TOKEN" \
    "https://api.github.com/repos/$SOURCE_OWNER/$SOURCE_REPO/forks" >/dev/null

  echo "Starting auto-commit every 5 minutes..."
  while true; do
    git add -A
    git commit -m "Auto-update $(date)" || echo "No changes to commit."
    git push origin "$BRANCH" || echo "Push failed, retrying next loop."
    sleep 300
  done
done
