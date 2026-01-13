#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/mobile-service-hub-41952-42033/MobileServiceHubMonolith"
[ -d "$WORKSPACE" ] || { echo "workspace missing: $WORKSPACE" >&2; exit 2; }
cd "$WORKSPACE"
export CI=true
export NODE_ENV=development
# run npm test in non-interactive mode; if no tests configured, exit 0
if jq -e '.scripts.test' package.json >/dev/null 2>&1; then
  npm test --silent || { echo 'tests failed' >&2; exit 40; }
else
  echo 'no test script defined, skipping'
fi
