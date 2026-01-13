#!/usr/bin/env bash
set -euo pipefail

# Validation script: build, start dev server, healthcheck, stop and record evidence
WORKSPACE="/home/kavia/workspace/code-generation/mobile-service-hub-41952-42033/MobileServiceHubMonolith"
cd "$WORKSPACE"
LOGDIR="$WORKSPACE/.logs"; mkdir -p "$LOGDIR"
# Local and fallback binaries
VITE_LOCAL="$WORKSPACE/node_modules/.bin/vite"
VITE_BIN="$VITE_LOCAL"
USE_GLOBAL=0
# Prefer local vite; allow global if local missing
if [ ! -x "$VITE_LOCAL" ]; then
  if command -v vite >/dev/null 2>&1; then
    VITE_BIN=$(command -v vite)
    USE_GLOBAL=1
    echo "using global vite: $VITE_BIN" >"$LOGDIR/vite_choice.log"
  else
    echo "vite not available (local or global)" >&2
    exit 10
  fi
fi
# Build
: >"$LOGDIR/vite_build.log"
if ! "$VITE_BIN" build >"$LOGDIR/vite_build.log" 2>&1; then
  cat "$LOGDIR/vite_build.log" >&2 || true
  cat > "$WORKSPACE/.validation_result" <<EOF
build=failed
build_log=$LOGDIR/vite_build.log
dev_server_used=$( [ $USE_GLOBAL -eq 1 ] && echo global || echo local )
EOF
  exit 11
fi
# Verify build artifact
if [ ! -f "$WORKSPACE/dist/index.html" ]; then
  echo "dist/index.html missing after build" >&2
  cat "$LOGDIR/vite_build.log" >&2 || true
  cat > "$WORKSPACE/.validation_result" <<EOF
build=missing_artifact
build_log=$LOGDIR/vite_build.log
dev_server_used=$( [ $USE_GLOBAL -eq 1 ] && echo global || echo local )
EOF
  exit 12
fi
# Start dev server in new process group
PORT=5173
: >"$LOGDIR/vite_dev.log"
# Use setsid to ensure new session/process group
setsid "$VITE_BIN" --port $PORT >"$LOGDIR/vite_dev.log" 2>&1 &
DEV_PID=$!
# small sleep to ensure process entry
sleep 0.5
# get process group id
PGID="$(ps -o pgid= -p "$DEV_PID" 2>/dev/null | tr -d ' ' || echo)"
# wait up to 30s for HTTP 200 at root
TIMEOUT=30
ok=0
for i in $(seq 1 $TIMEOUT); do
  if curl -sSf --max-time 2 "http://127.0.0.1:$PORT/" >/dev/null 2>&1; then
    ok=1
    break
  fi
  sleep 1
done
# final HTTP status (may fail)
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:$PORT/" || true)
# inspect dev log for errors (case-insensitive)
if grep -i -E '(^|[^a-z0-9])(error|failed|exception)([^a-z0-9]|$)' "$LOGDIR/vite_dev.log" >/dev/null 2>&1; then DEV_LOG_ERRORS=1; else DEV_LOG_ERRORS=0; fi
# stop server (kill entire process group) if started
if [ -n "$PGID" ] && [ "$PGID" -gt 0 ] 2>/dev/null; then
  sudo kill -TERM -"$PGID" >/dev/null 2>&1 || true
  sleep 1
  sudo kill -KILL -"$PGID" >/dev/null 2>&1 || true
fi
# wait for process to exit
if [ -n "$DEV_PID" ]; then
  wait "$DEV_PID" 2>/dev/null || true
fi
# compose validation result
cat > "$WORKSPACE/.validation_result" <<EOF
build=ok
build_log=$LOGDIR/vite_build.log
dev_server_used=$( [ $USE_GLOBAL -eq 1 ] && echo global || echo local )
dev_server_health_http_status=$HTTP_STATUS
dev_server_log=$LOGDIR/vite_dev.log
dev_server_log_had_errors=$DEV_LOG_ERRORS
test_result_file=$WORKSPACE/.validation_test_result
EOF

# Decide overall success: must have responded with 200 and no dev log errors
if [ "$ok" -ne 1 ] || [ "$HTTP_STATUS" != "200" ] || [ "$DEV_LOG_ERRORS" -eq 1 ]; then
  echo "validation failed; see $WORKSPACE/.validation_result and logs" >&2
  exit 13
fi

exit 0
