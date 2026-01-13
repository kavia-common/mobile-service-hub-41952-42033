#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/mobile-service-hub-41952-42033/MobileServiceHubMonolith"
cd "$WORKSPACE"
mkdir -p "$WORKSPACE" "$WORKSPACE/logs"
LOG="$WORKSPACE/logs/scaffold.log"
# Guard: if node_modules exists but package.json missing, fail
if [ -d node_modules ] && [ ! -f package.json ]; then
  echo 'node_modules exists but package.json missing; aborting' >&2; exit 20
fi
# If package.json exists, ensure start and build scripts exist
if [ -f package.json ]; then
  node -e "const fs=require('fs'); try{const p=JSON.parse(fs.readFileSync('package.json')); const s=p.scripts||{}; if(s.start&&s.build) process.exit(0); else process.exit(2)}catch(e){process.exit(1)}"; RC=$?
  if [ $RC -eq 0 ]; then
    exit 0
  elif [ $RC -eq 2 ]; then
    echo 'package.json exists but missing start/build scripts; aborting scaffold' >&2; exit 21
  else
    echo 'failed to read package.json; aborting' >&2; exit 22
  fi
fi
USE_YARN_FLAG=""
if [ -f yarn.lock ] && command -v yarn >/dev/null 2>&1; then USE_YARN_FLAG='--use-yarn'; fi
CRA_VERSION=${CRA_VERSION:-}
# Prefer system create-react-app, else npx
if command -v create-react-app >/dev/null 2>&1 && [ -z "$CRA_VERSION" ]; then
  create-react-app . $USE_YARN_FLAG > "$LOG" 2>&1 || (tail -n 200 "$LOG" >&2; echo 'create-react-app (system) failed; see scaffold.log' >&2; exit 23)
else
  if command -v npx >/dev/null 2>&1; then
    NPX_ARG="create-react-app"
    [ -n "$CRA_VERSION" ] && NPX_ARG="create-react-app@${CRA_VERSION}"
    # Run npx directly without creating scripts on disk
    npx --yes $NPX_ARG . $USE_YARN_FLAG > "$LOG" 2>&1 || (
      tail -n 200 "$LOG" >&2
      # If permission or mount errors occur, attempt sudo-exec fallback to avoid creating exec files
      if sudo -n true 2>/dev/null; then
        sudo bash -c "cd '$WORKSPACE' && npx --yes $NPX_ARG . $USE_YARN_FLAG" > "$LOG" 2>&1 || (tail -n 200 "$LOG" >&2; echo 'create-react-app (npx sudo) failed' >&2; exit 24)
      else
        echo 'create-react-app (npx) failed and sudo not available; see scaffold.log' >&2; exit 24
      fi
    )
  else
    echo 'no create-react-app available (system or npx); cannot scaffold' >&2; exit 25
  fi
fi
# Ensure package.json contains start/build/test scripts (idempotent)
node -e "const fs=require('fs'); const p=fs.existsSync('package.json')?JSON.parse(fs.readFileSync('package.json')):{name:'mobile-service-hub'}; p.scripts=p.scripts||{}; p.scripts.start=p.scripts.start||'react-scripts start'; p.scripts.build=p.scripts.build||'react-scripts build'; p.scripts.test=p.scripts.test||'react-scripts test --env=jsdom'; fs.writeFileSync('package.json',JSON.stringify(p,null,2));" || (echo 'failed to ensure package.json scripts' >&2; exit 26)
