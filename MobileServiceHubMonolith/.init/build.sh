#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/mobile-service-hub-41952-42033/MobileServiceHubMonolith"
cd "$WORKSPACE"
export NODE_ENV=development HOST=0.0.0.0 PORT=${PORT:-3000}
USE_YARN=0
if [ -f yarn.lock ] && command -v yarn >/dev/null 2>&1; then USE_YARN=1; fi
# detect build script
if node -e "try{const pj=require('./package.json'); process.exit(pj.scripts&&pj.scripts.build?0:1);}catch(e){process.exit(1)}" 2>/dev/null; then
  if [ -x ./node_modules/.bin/react-scripts ]; then
    ./node_modules/.bin/react-scripts build
  else
    if [ "$USE_YARN" -eq 1 ]; then
      yarn build
    else
      npm run build
    fi
  fi
  if [ -d build ]; then echo "BUILD_OUT=build"; elif [ -d dist ]; then echo "BUILD_OUT=dist"; else echo "build output missing" >&2; exit 22; fi
else
  echo "no build script; skipping build"
fi
