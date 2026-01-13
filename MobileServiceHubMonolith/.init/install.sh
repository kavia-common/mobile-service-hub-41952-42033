#!/usr/bin/env bash
set -euo pipefail

# Ensure workspace and .init exist and that current user can create/chmod/execute helper scripts
WORKSPACE="/home/kavia/workspace/code-generation/mobile-service-hub-41952-42033/MobileServiceHubMonolith"
mkdir -p "$WORKSPACE" "$WORKSPACE/.init"

TEST_FILE="$WORKSPACE/.init/.perm_test_$$"
# Create a test file (non-failing)
: > "$TEST_FILE" 2>/dev/null || true

# Try to make it executable; if that fails, repair ownership/permissions and retry
if ! chmod +x "$TEST_FILE" 2>/dev/null; then
  # Attempt minimal fixes using sudo only when needed
  sudo chown -R "$(id -u):$(id -g)" "$WORKSPACE" || true
  sudo chmod -R u+rwX "$WORKSPACE" || true
  : > "$TEST_FILE" || true
  chmod +x "$TEST_FILE" || true
fi

# Clean up test file and exit
rm -f "$TEST_FILE" || true
exit 0
