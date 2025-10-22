#!/bin/bash
set -e

WORKDIR="/workspace/workshop"
TOKEN_FILE="$WORKDIR/github_token.txt"

cd "$WORKDIR"

SOURCE_REPO=$(basename -s .git "$(git config --get remote.origin.url)")
SOURCE_OWNER=$(git config --get remote.origin.url | sed -E 's|.*github\.com[:/](.+)/.+\.git|\1|')
BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "Detected repo: $SOURCE_OWNER/$SOURCE_REPO (branch: $BRANCH)"

touch "$TOKEN_FILE"
if ! grep -qx "github_token.txt" .gitignore 2>/dev/null; then
  [ -s .gitignore ] && sed -i -e '$a\' .gitignore
  {
    echo ""
    echo "# CRITICAL"
    echo "github_token.txt"
  } >> .gitignore
  echo "Added github_token.txt to .gitignore"
fi

echo "Monitoring for a GitHub token in $TOKEN_FILE..."

while true; do
  if [ ! -s "$TOKEN_FILE" ]; then
    echo "No token found yet — waiting 2 minutes..."
    sleep 120
    continue
  fi

  TOKEN=$(cat "$TOKEN_FILE")
  echo "Checking GitHub token validity..."
  USER_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}\n" -H "Authorization: token $TOKEN" https://api.github.com/user)
  echo "GitHub /user API response:"
  echo "$USER_RESPONSE"

  USERNAME=$(echo "$USER_RESPONSE" | jq -r '.login')
  HTTP_CODE=$(echo "$USER_RESPONSE" | grep HTTP_CODE | cut -d':' -f2)

  if [ "$HTTP_CODE" != "200" ] || [ -z "$USERNAME" ] || [ "$USERNAME" == "null" ]; then
    echo "Invalid or expired GitHub token (HTTP $HTTP_CODE) — waiting 2 minutes..."
    sleep 120
    continue
  fi

  echo "Valid token detected for $USERNAME — proceeding with fork and auto-commit setup."
  DEST_REPO="https://$USERNAME:$TOKEN@github.com/$USERNAME/$SOURCE_REPO.git"

  git config user.name "$USERNAME"
  git config user.email "$USERNAME@users.noreply.github.com"
  git remote set-url origin "$DEST_REPO"

  echo "Forking $SOURCE_OWNER/$SOURCE_REPO to $USERNAME..."
  FORK_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}\n" -X POST \
    -H "Authorization: token $TOKEN" \
    "https://api.github.com/repos/$SOURCE_OWNER/$SOURCE_REPO/forks")
  echo "GitHub /forks API response:"
  echo "$FORK_RESPONSE"
  FORK_CODE=$(echo "$FORK_RESPONSE" | grep HTTP_CODE | cut -d':' -f2)
  echo "Fork HTTP status: $FORK_CODE"

  echo "Waiting for fork to appear..."
  for ((i=1; i<=12; i++)); do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
      -H "Authorization: token $TOKEN" \
      "https://api.github.com/repos/$USERNAME/$SOURCE_REPO")
    if [ "$STATUS" -eq 200 ]; then
      echo "Fork found on GitHub (attempt $i)."
      break
    fi
    echo "Attempt $i: fork not visible yet, waiting 5s..."
    sleep 5
  done

  echo "Setting $USERNAME/$SOURCE_REPO to private..."
  PATCH_RESPONSE=$(curl -s -w "\nHTTP_CODE:%{http_code}\n" \
    -X PATCH \
    -H "Authorization: token $TOKEN" \
    -H "Accept: application/vnd.github+json" \
    "https://api.github.com/repos/$USERNAME/$SOURCE_REPO" \
    -d '{"private": true}')
  echo "GitHub PATCH /repos API response:"
  echo "$PATCH_RESPONSE"

  PATCH_CODE=$(echo "$PATCH_RESPONSE" | grep HTTP_CODE | cut -d':' -f2)
  if [ "$PATCH_CODE" -eq 200 ]; then
    echo "Repository successfully set to private."
  else
    echo "Warning: failed to set private (HTTP $PATCH_CODE)."
  fi

  echo "Starting auto-commit every 5 minutes..."
  while true; do
    git add -A
    git commit -m "Auto-update $(date)" || echo "No changes to commit."
    git push origin "$BRANCH" --force || echo "Push failed, retrying next loop."
    sleep 300
  done
done
