#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/mobile-service-hub-41952-42033/MobileServiceHubMonolith"
[ -d "$WORKSPACE" ] || { echo "workspace missing: $WORKSPACE" >&2; exit 2; }
cd "$WORKSPACE"
export CI=true
export NODE_ENV=development
PORT=${PORT:-3000}
LOG=/tmp/mobile_service_hub.validation.log
: >"$LOG"
# determine start script
START_CMD=$(node -e "try{const p=require('./package.json'); console.log((p.scripts&&p.scripts.start)||'');}catch(e){console.log('')}") || true
if echo "$START_CMD" | grep -q "react-scripts"; then
  CMD="BROWSER=none react-scripts start"
elif echo "$START_CMD" | grep -q "vite"; then
  CMD="vite"
elif [ -n "$START_CMD" ]; then
  CMD="$START_CMD"
else
  echo "no start script found" >&2; exit 10
fi
setsid sh -c "PORT=$PORT $CMD" >"$LOG" 2>&1 &
PID=$!
sleep 0.5
PGID=$(ps -o pgid= -p $PID | tr -d ' ' || echo "")
if [ -z "$PGID" ]; then PGID=$PID; fi
echo "started PID=$PID PGID=$PGID" >>"$LOG"
echo "$PID" > /tmp/.mobile_service_hub.pid
echo "$PGID" > /tmp/.mobile_service_hub.pgid
