#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/mobile-service-hub-41952-42033/MobileServiceHubMonolith"
cd "$WORKSPACE"
LOGDIR="$WORKSPACE/.logs"; mkdir -p "$LOGDIR"
RETRIES=3; SLEEP=2
# validate node & npm
if ! command -v node >/dev/null 2>&1 || ! command -v npm >/dev/null 2>&1; then
  echo "node and/or npm not installed" >&2; exit 2
fi
NODE_V=$(node -v | sed 's/^v//')
# require Node >=18
req_major=18
major=$(printf "%s" "$NODE_V" | cut -d. -f1)
if [ "$major" -lt "$req_major" ]; then
  echo "Node >= $req_major required, found $NODE_V" >&2; exit 3
fi
# idempotent short-circuit: if local vite binary and react exist, assume deps present
if [ -x "$WORKSPACE/node_modules/.bin/vite" ] && [ -d "$WORKSPACE/node_modules/react" ]; then
  echo "local deps present" >"$LOGDIR/install_status.log"
  echo "local vite used" >"$LOGDIR/vite_choice.log"
  exit 0
fi
run_npm_ci(){ npm ci --no-audit --no-fund --prefer-offline >"$LOGDIR/npm_ci.log" 2>&1; }
run_npm_install(){ npm i --no-audit --no-fund --prefer-offline >"$LOGDIR/npm_install.log" 2>&1; }
# choose install strategy
if [ -f package-lock.json ]; then
  attempt=1
  until run_npm_ci && break || [ $attempt -ge $RETRIES ]; do
    attempt=$((attempt+1))
    sleep $SLEEP
  done
  if [ $attempt -ge $RETRIES ] && [ ! -x "$WORKSPACE/node_modules/.bin/vite" ]; then
    echo "npm ci failed after retries; see $LOGDIR/npm_ci.log" >&2
  fi
else
  attempt=1
  until run_npm_install && break || [ $attempt -ge $RETRIES ]; do
    attempt=$((attempt+1))
    sleep $SLEEP
  done
  if [ $attempt -ge $RETRIES ] && [ ! -x "$WORKSPACE/node_modules/.bin/vite" ]; then
    echo "npm install failed after retries; see $LOGDIR/npm_install.log" >&2
  fi
fi
# verify local vite; if missing, allow fallback to global vite but log it
if [ -x "$WORKSPACE/node_modules/.bin/vite" ]; then
  echo "local vite used" >"$LOGDIR/vite_choice.log"
elif command -v vite >/dev/null 2>&1; then
  echo "local vite missing; using global vite" >"$LOGDIR/vite_choice.log"
else
  echo "vite not available locally or globally; install failed" >&2
  [ -f "$LOGDIR/npm_install.log" ] && cat "$LOGDIR/npm_install.log" >&2 || true
  [ -f "$LOGDIR/npm_ci.log" ] && cat "$LOGDIR/npm_ci.log" >&2 || true
  exit 7
fi
# verify react
if [ -d "$WORKSPACE/node_modules/react" ]; then
  echo "react installed locally" >"$LOGDIR/install_status.log"
else
  echo "react not installed locally" >"$LOGDIR/install_status.log"
fi
exit 0
