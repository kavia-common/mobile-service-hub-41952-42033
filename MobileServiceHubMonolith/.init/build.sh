#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/mobile-service-hub-41952-42033/MobileServiceHubMonolith"
cd "$WORKSPACE" || (echo 'workspace missing; cannot build' >&2; exit 50)
mkdir -p "$WORKSPACE/logs"
VAL_LOG="$WORKSPACE/logs/validation.log"
: "# ensure npm/node available"
command -v node >/dev/null 2>&1 || (echo 'node not found' >&2; exit 60)
command -v npm >/dev/null 2>&1 || (echo 'npm not found' >&2; exit 61)
PORT=${PORT:-3005}
HOST=127.0.0.1
npm run build > "$VAL_LOG" 2>&1 || (tail -n 200 "$VAL_LOG" >&2; echo 'npm run build failed; see validation.log' >&2; exit 51)
