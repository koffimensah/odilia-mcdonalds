#!/bin/bash

set -e

echo "======================================"
echo "   GitHub Actions Linux Runner Setup   "
echo "======================================"

# --------------------------------------
# Variables (UPDATE THESE)
# --------------------------------------
RUNNER_VERSION="2.329.0"
REPO_URL="YOUR-REPO-URL"
TOKEN="YOUR-TOKEN"
RUNNER_NAME="linux-runner-01"
WORK_DIR="_work"
SHA256="a932fc36bbce3786c3478536afd12bfd36d1d0777cxxxxxx"  # Example placeholder, update hash if needed

# NOTE: Linux runner SHA256 is different — you can get it from GitHub releases page.
# If you want, I can fetch the correct hash for your OS.

# --------------------------------------
# Create directory
# --------------------------------------
echo "[1/7] Creating directory..."
mkdir -p actions-runner
cd actions-runner

# --------------------------------------
# Download runner
# --------------------------------------
echo "[2/7] Downloading GitHub runner..."
FILE="actions-runner-linux-x64-$RUNNER_VERSION.tar.gz"
DOWNLOAD_URL="https://github.com/actions/runner/releases/download/v$RUNNER_VERSION/$FILE"

curl -o $FILE -L $DOWNLOAD_URL

# --------------------------------------
# Validate checksum (optional but recommended)
# --------------------------------------
echo "[3/7] Validating checksum..."
DOWNLOADED_HASH=$(sha256sum $FILE | awk '{ print toupper($1) }')

if [ "$DOWNLOADED_HASH" != "$SHA256" ]; then
    echo "❌ ERROR: Checksum mismatch!"
    echo "Expected: $SHA256"
    echo "Got:      $DOWNLOADED_HASH"
    exit 1
fi

echo "✔ Checksum validated"

# --------------------------------------
# Extract runner
# --------------------------------------
echo "[4/7] Extracting runner..."
tar xzf $FILE

# --------------------------------------
# Configure runner (non-interactive)
# --------------------------------------
echo "[5/7] Configuring runner..."

./config.sh --unattended \
  --url "$REPO_URL" \
  --token "$TOKEN" \
  --name "$RUNNER_NAME" \
  --work "$WORK_DIR"

echo "✔ Runner configured"

# --------------------------------------
# Install & start as a service
# --------------------------------------
echo "[6/7] Installing service..."
sudo ./svc.sh install

echo "[7/7] Starting service..."
sudo ./svc.sh start

echo "======================================"
echo "🎉 GitHub Linux Runner is installed!"
echo "🚀 Runner Name: $RUNNER_NAME"
echo "🟢 Service is running in the background"
echo "======================================"
