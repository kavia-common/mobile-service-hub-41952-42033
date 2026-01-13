#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/mobile-service-hub-41952-42033/MobileServiceHubMonolith"
[ -d "$WORKSPACE" ] || { echo "workspace missing: $WORKSPACE" >&2; exit 2; }
cd "$WORKSPACE"
export CI=true
export NODE_ENV=development
LOG=/tmp/mobile_service_hub.validation.log
: >"$LOG"
# run build non-interactively
npm run build --silent >"$LOG" 2>&1 || { sed -n '1,400p' "$LOG" >&2; echo 'build failed' >&2; exit 30; }
OUT_DIR="build"
[ -d "$OUT_DIR" ] || { echo "expected build output $OUT_DIR missing" >&2; exit 31; }
echo "build ok"
