#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/mobile-service-hub-41952-42033/MobileServiceHubMonolith"
cd "$WORKSPACE"
export NODE_ENV=development HOST=0.0.0.0 PORT=${PORT:-3000}
LOG=/tmp/react_dev.log
PID_FILE=/tmp/react_dev.pid
USE_YARN=0
if [ -f yarn.lock ] && command -v yarn >/dev/null 2>&1; then USE_YARN=1; fi
# start using local binaries when available
if [ -x ./node_modules/.bin/react-scripts ]; then
  setsid sh -c "exec ./node_modules/.bin/react-scripts start" > "$LOG" 2>&1 &
else
  if [ "$USE_YARN" -eq 1 ]; then
    setsid sh -c "exec yarn start" > "$LOG" 2>&1 &
  else
    setsid sh -c "exec npm start" > "$LOG" 2>&1 &
  fi
fi
printf "%s" "$!" > "$PID_FILE"
echo "started: pid=$(cat $PID_FILE) log=$LOG"
