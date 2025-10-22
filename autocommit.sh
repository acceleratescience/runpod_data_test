#!/bin/bash
set -e

WORKDIR="/workspace/workshop"
TOKEN_FILE="$WORKDIR/github_token.txt"

cd "$WORKDIR"

# --- Auto-detect repo info ---
SOURCE_REPO=$(basename -s .git "$(git config --get remote.origin.url)")
SOURCE_OWNER=$(git config --get remote.origin.url | sed -E 's|.*github\.com[:/](.+)/.+\.git|\1|')
BRANCH=$(git rev-parse --abbrev-ref HEAD)

echo "Detected repo: $SOURCE_OWNER/$SOURCE_REPO (branch: $BRANCH)"

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
    echo "Invalid or expired GitHub token — waiting 2 minutes..."
    sleep 120
    continue
  fi

  echo "Valid token detected for $USERNAME — proceeding with fork and auto-commit setup."
  DEST_REPO="https://$USERNAME:$TOKEN@github.com/$USERNAME/$SOURCE_REPO.git"

  # --- Configure Git identity and remote ---
  git config user.name "$USERNAME"
  git config user.email "$USERNAME@users.noreply.github.com"
  git remote set-url origin "$DEST_REPO"

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
