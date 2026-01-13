#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/mobile-service-hub-41952-42033/MobileServiceHubMonolith"
cd "$WORKSPACE" || (echo 'workspace missing; cannot test' >&2; exit 50)
VAL_LOG="$WORKSPACE/logs/validation.log"
PORT=${PORT:-3005}
HOST=127.0.0.1
TRIES=0
until curl -sS --max-time 2 "http://$HOST:$PORT" >/dev/null 2>&1 || [ $TRIES -ge 10 ]; do TRIES=$((TRIES+1)); sleep 2; done
if curl -sS --max-time 2 "http://$HOST:$PORT" >/dev/null 2>&1; then
  echo 'ok'
  exit 0
else
  echo 'not responding' >&2
  tail -n 200 "$VAL_LOG" >&2 || true
  exit 53
fi
