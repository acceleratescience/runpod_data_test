#!/bin/bash
set -e

WORKDIR="/workspace/workshop"
TOKEN_FILE="$WORKDIR/github_token.txt"

cd "$WORKDIR"

# --- Detect repo info automatically ---
SOURCE_REPO=$(basename -s .git "$(git config --get remote.origin.url)")
SOURCE_OWNER=$(git config --get remote.origin.url | sed -E 's|.*github\.com[:/](.+)/.+\.git|\1|')
BRANCH=$(git rev-parse --abbrev-ref HEAD)
echo "Detected repo: $SOURCE_OWNER/$SOURCE_REPO (branch: $BRANCH)"

# --- Ensure token file exists and ignored ---
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
  # --- Wait for token ---
  if [ ! -s "$TOKEN_FILE" ]; then
    echo "No token found yet — waiting 2 minutes..."
    sleep 120
    continue
  fi

  TOKEN=$(cat "$TOKEN_FILE")

  echo "Checking GitHub token validity..."
  # Save JSON and HTTP code separately
  HTTP_CODE=$(curl -s -o /tmp/user.json -w "%{http_code}" \
    -H "Authorization: token $TOKEN" https://api.github.com/user)
  echo "GitHub /user API response (HTTP $HTTP_CODE):"
  cat /tmp/user.json
  echo ""

  USERNAME=$(jq -r '.login' /tmp/user.json 2>/dev/null || echo "")
  if [ "$HTTP_CODE" != "200" ] || [ -z "$USERNAME" ] || [ "$USERNAME" == "null" ]; then
    echo "Invalid or expired GitHub token (HTTP $HTTP_CODE) — waiting 2 minutes..."
    sleep 120
    continue
  fi

  echo "Valid token detected for $USERNAME — proceeding with private repo setup."

  # --- Create or reuse a private repo ---
  NEW_NAME="${SOURCE_REPO}-private"

  # Check if private repo already exists
  EXISTS=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: token $TOKEN" \
    "https://api.github.com/repos/$USERNAME/$NEW_NAME")

  if [ "$EXISTS" -eq 200 ]; then
    echo "Private repo $USERNAME/$NEW_NAME already exists — skipping creation."
  else
    echo "Creating new private repo $USERNAME/$NEW_NAME..."
    CREATE_CODE=$(curl -s -o /tmp/create.json -w "%{http_code}" \
      -X POST -H "Authorization: token $TOKEN" \
      -H "Accept: application/vnd.github+json" \
      "https://api.github.com/user/repos" \
      -d "{\"name\": \"$NEW_NAME\", \"private\": true}")
    echo "GitHub /user/repos API response (HTTP $CREATE_CODE):"
    cat /tmp/create.json
    echo ""
  fi

  # --- Point git remote to private repo ---
  DEST_REPO="https://$USERNAME:$TOKEN@github.com/$USERNAME/$NEW_NAME.git"
  git config user.name "$USERNAME"
  git config user.email "$USERNAME@users.noreply.github.com"
  git remote set-url origin "$DEST_REPO"

  echo "Remote now points to private repo $USERNAME/$NEW_NAME."

  # --- Auto-commit loop ---
  echo "Starting auto-commit every 5 minutes..."
  while true; do
    git add -A
    git commit -m "Auto-update $(date)" || echo "No changes to commit."
    git push origin "$BRANCH" --force || echo "Push failed, retrying next loop."
    sleep 300
  done
done
