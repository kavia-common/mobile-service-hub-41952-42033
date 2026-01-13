#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/mobile-service-hub-41952-42033/MobileServiceHubMonolith"
cd "$WORKSPACE"
export NODE_ENV=development HOST=0.0.0.0 PORT=${PORT:-3000}
PORT_VAL=${PORT:-3000}
# run build script
./.init/build.sh || true
# start server
./.init/start.sh
LEADER_PID=$(cat /tmp/react_dev.pid 2>/dev/null || true)
TRIES=0; MAX=90
while ! curl -sSf "http://127.0.0.1:${PORT_VAL}" >/dev/null 2>&1 && [ $TRIES -lt $MAX ]; do sleep 1; TRIES=$((TRIES+1)); done
if curl -sSf -o /dev/null "http://127.0.0.1:${PORT_VAL}"; then
  echo "validation: server responded on port ${PORT_VAL}"
else
  echo "validation: server did not respond within timeout (${MAX}s)" >&2
  [ -f /tmp/react_dev.log ] && tail -n 200 /tmp/react_dev.log >&2 || true
  # attempt cleanup
  if [ -n "$LEADER_PID" ]; then
    PKGID=$(ps -o pgid= "$LEADER_PID" 2>/dev/null | tr -d ' ' || true)
    if [ -n "$PKGID" ]; then kill -TERM -"$PKGID" || true; else kill -TERM "$LEADER_PID" || true; fi
  fi
  sleep 2
  exit 23
fi
# graceful shutdown
if [ -n "$LEADER_PID" ]; then
  PKGID=$(ps -o pgid= "$LEADER_PID" 2>/dev/null | tr -d ' ' || true)
  if [ -n "$PKGID" ]; then kill -TERM -"$PKGID" || true; else kill -TERM "$LEADER_PID" || true; fi
fi
sleep 2
# report build output existence and tail of log
if [ -d build ]; then echo "build output: build exists"; elif [ -d dist ]; then echo "build output: dist exists"; fi
[ -f /tmp/react_dev.log ] && tail -n 100 /tmp/react_dev.log || true
exit 0
