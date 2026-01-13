#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/mobile-service-hub-41952-42033/MobileServiceHubMonolith"
cd "$WORKSPACE" || (echo 'workspace missing; cannot start' >&2; exit 50)
mkdir -p "$WORKSPACE/logs"
VAL_LOG="$WORKSPACE/logs/validation.log"
SERVER_PID_FILE="$WORKSPACE/logs/validation_server.pid"
rm -f "$SERVER_PID_FILE"
PORT=${PORT:-3005}
HOST=127.0.0.1
# Try to serve build directory
if [ -d build ]; then
  if command -v http-server >/dev/null 2>&1; then
    (cd build && setsid http-server -p "$PORT" --silent --spa > "$VAL_LOG" 2>&1 &)
    sleep 0.5
    pgrep -f "http-server.*-p.*$PORT" | head -n1 > "$SERVER_PID_FILE" || true
  elif command -v python3 >/dev/null 2>&1; then
    (cd build && setsid python3 -m http.server "$PORT" > "$VAL_LOG" 2>&1 &)
    sleep 0.5
    pgrep -f "python3 -m http.server $PORT" | head -n1 > "$SERVER_PID_FILE" || true
  elif command -v npx >/dev/null 2>&1; then
    (cd build && setsid npx --yes http-server -p "$PORT" --silent --spa > "$VAL_LOG" 2>&1 &)
    sleep 1
    pgrep -f "http-server.*-p.*$PORT" | head -n1 > "$SERVER_PID_FILE" || true
  else
    echo 'no static server available; cannot serve build' >&2
    exit 52
  fi
else
  echo 'build directory not found; cannot serve build' >&2
  exit 54
fi
# Return PID file path on success (may be empty if pgrep failed)
if [ -f "$SERVER_PID_FILE" ]; then cat "$SERVER_PID_FILE"; else echo; fi
