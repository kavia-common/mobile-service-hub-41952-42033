#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/mobile-service-hub-41952-42033/MobileServiceHubMonolith"
cd "$WORKSPACE" || (echo 'workspace missing; cannot validate' >&2; exit 50)
mkdir -p "$WORKSPACE/logs"
VAL_LOG="$WORKSPACE/logs/validation.log"
PORT=${PORT:-3005}
HOST=127.0.0.1
# Build
bash .init/build.sh
# Start server to serve build
PIDFILE="$WORKSPACE/logs/validation_server.pid"
if bash .init/start.sh; then
  SERVER_PID=$(cat "$PIDFILE" 2>/dev/null || true)
else
  # start.sh will exit non-zero if no static server available; attempt to run CRA dev server headless
  echo 'serving build failed, attempting CRA dev server' >> "$VAL_LOG" 2>&1
  BROWSER=none HOST=$HOST PORT=$PORT NODE_ENV=development setsid npm start > "$VAL_LOG" 2>&1 &
  sleep 1
  DEV_PID=$(pgrep -f "react-scripts start" | head -n1 || true)
  [ -n "$DEV_PID" ] && echo "$DEV_PID" > "$PIDFILE"
  SERVER_PID=$DEV_PID
fi
# wait for response
TRIES=0
until curl -sS --max-time 2 "http://$HOST:$PORT" >/dev/null 2>&1 || [ $TRIES -ge 20 ]; do TRIES=$((TRIES+1)); sleep 2; done
if curl -sS --max-time 2 "http://$HOST:$PORT" >/dev/null 2>&1; then
  # determine mode
  if [ -n "${SERVER_PID:-}" ]; then
    echo 'validation_success' >&1
  else
    echo 'validation_success' >&1
  fi
  # cleanup
  bash .init/stop.sh || true
  exit 0
else
  tail -n 200 "$VAL_LOG" >&2 || true
  bash .init/stop.sh || true
  echo 'validation failed: server did not respond' >&2
  exit 53
fi
