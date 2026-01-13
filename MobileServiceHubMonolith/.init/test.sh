#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/mobile-service-hub-41952-42033/MobileServiceHubMonolith"
cd "$WORKSPACE"
# Prefer local jest/react-scripts if present
if [ -x ./node_modules/.bin/jest ]; then
  ./node_modules/.bin/jest --version >/dev/null 2>&1 || true
  ./node_modules/.bin/jest --runInBand --colors --reporters=default || { echo "tests failed" >&2; exit 1; }
elif [ -x ./node_modules/.bin/react-scripts ]; then
  ./node_modules/.bin/react-scripts test --watchAll=false --ci || { echo "tests failed" >&2; exit 1; }
else
  echo "no test runner found; skipping tests"
fi
