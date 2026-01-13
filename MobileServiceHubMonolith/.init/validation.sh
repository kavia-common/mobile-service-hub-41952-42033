#!/usr/bin/env bash
set -euo pipefail

WORKSPACE="/home/kavia/workspace/code-generation/mobile-service-hub-41952-42033/MobileServiceHubMonolith"
[ -d "$WORKSPACE" ] || { echo "workspace missing: $WORKSPACE" >&2; exit 2; }
cd "$WORKSPACE"
export CI=true
export NODE_ENV=development
PORT=${PORT:-3000}
HEALTH_PATH=${HEALTH_PATH:-/}
TIMEOUT=${TIMEOUT:-60}
LOG=/tmp/mobile_service_hub.validation.log
: >"$LOG"

# determine start script
START_CMD=$(node -e "try{const p=require('./package.json'); console.log((p.scripts&&p.scripts.start)||'');}catch(e){console.log('')}]" 2>/dev/null || true)
# fallback robust eval for older node shells if above fails
if [ -z "$START_CMD" ]; then
  START_CMD=$(node -e "try{const p=require('./package.json'); console.log((p.scripts&&p.scripts.start)||'');}catch(e){process.stdout.write('')}") || true
fi
IS_REACT_START=0
IS_VITE=0
echo "start script: $START_CMD" >>"$LOG"
case "$START_CMD" in
  *react-scripts* ) IS_REACT_START=1 ;;
  *vite* ) IS_VITE=1 ;;
esac

# If unknown start script but present -> run build only
if [ $IS_REACT_START -eq 0 ] && [ $IS_VITE -eq 0 ] && [ -n "$START_CMD" ]; then
  npm run build --silent >"$LOG" 2>&1 || { sed -n '1,400p' "$LOG" >&2; echo 'build failed' >&2; exit 30; }
  OUT_DIR="build"
  [ -d "$OUT_DIR" ] || { echo "expected build output $OUT_DIR missing" >&2; exit 31; }
  echo "build ok" >>"$LOG"
  exit 0
fi

# For vite/react, optionally build then start dev server
if [ $IS_VITE -eq 1 ]; then
  npm run build --silent >>"$LOG" 2>&1 || echo 'vite build warning' >>"$LOG"
  START_CMD="vite"
elif [ $IS_REACT_START -eq 1 ]; then
  npm run build --silent >>"$LOG" 2>&1 || echo 'react-scripts build warning' >>"$LOG"
  START_CMD="BROWSER=none react-scripts start"
fi

# start dev server in new session and capture PGID
setsid sh -c "PORT=$PORT $START_CMD" >"$LOG" 2>&1 &
PID=$!
sleep 0.5
PGID=$(ps -o pgid= -p $PID | tr -d ' ' || echo "")
if [ -z "$PGID" ]; then PGID=$PID; fi
echo "started PID=$PID PGID=$PGID" >>"$LOG"

# wait for health
for i in $(seq 1 $TIMEOUT); do
  HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "http://127.0.0.1:$PORT${HEALTH_PATH}" || true)
  if [ -n "$HTTP_STATUS" ] && [ "$HTTP_STATUS" != "000" ] && [ "$HTTP_STATUS" -ge 200 ] && [ "$HTTP_STATUS" -lt 400 ]; then
    echo "validation ok: http_status=$HTTP_STATUS" | tee -a "$LOG"
    break
  fi
  sleep 1
  if [ $i -eq $TIMEOUT ]; then
    echo "server failed to respond on port $PORT; last_status=$HTTP_STATUS" >&2
    echo '---- server log ----' >&2; sed -n '1,400p' "$LOG" >&2 || true
    # kill by PGID
    if [ -n "$PGID" ]; then kill -TERM -"$PGID" 2>/dev/null || true; fi
    wait $PID 2>/dev/null || true
    exit 33
  fi
done

# clean stop by PGID
if [ -n "$PGID" ]; then kill -TERM -"$PGID" 2>/dev/null || true; fi
wait $PID 2>/dev/null || true
exit 0
