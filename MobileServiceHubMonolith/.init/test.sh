#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/mobile-service-hub-41952-42033/MobileServiceHubMonolith"
cd "$WORKSPACE"
LOGDIR="$WORKSPACE/.logs"; mkdir -p "$LOGDIR"
# fail if test deps missing; dependencies step must install them
for dep in node_modules/jest node_modules/babel-jest node_modules/@babel/preset-react node_modules/react-test-renderer; do
  if [ ! -d "$dep" ]; then echo "test dependency missing: $dep" >&2; exit 8; fi
done
# jest config for transforming JSX via babel-jest
if [ ! -f jest.config.js ]; then
  cat > jest.config.js <<'JCFG'
module.exports = { testEnvironment: 'jsdom', transform: { '^.+\\.[tj]sx?$': 'babel-jest' } };
JCFG
fi
# smoke test
mkdir -p __tests__
cat > __tests__/app-smoke.test.jsx <<'TEST'
import React from 'react'
import renderer from 'react-test-renderer'
import App from '../src/App'
test('App smoke', () => { const tree = renderer.create(<App/>).toJSON(); expect(tree).toBeTruthy(); })
TEST
# run local jest
if [ -x node_modules/.bin/jest ]; then
  node_modules/.bin/jest --runInBand >"$LOGDIR/jest_run.log" 2>&1 || { cat "$LOGDIR/jest_run.log" >&2; exit 9; }
else
  echo "local jest missing" >&2; exit 10
fi
# record test evidence
echo "jest_log=$LOGDIR/jest_run.log" > "$WORKSPACE/.validation_test_result"
exit 0
