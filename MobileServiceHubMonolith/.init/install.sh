#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/mobile-service-hub-41952-42033/MobileServiceHubMonolith"
cd "$WORKSPACE"
mkdir -p "$WORKSPACE/logs"
INSTALL_LOG="$WORKSPACE/logs/install.log"
if [ -f yarn.lock ] && command -v yarn >/dev/null 2>&1; then
  yarn --silent --non-interactive > "$INSTALL_LOG" 2>&1 || (tail -n 200 "$INSTALL_LOG" >&2; echo 'yarn install failed; see install.log' >&2; exit 30)
else
  if [ -f package-lock.json ]; then
    npm ci --prefer-offline --no-audit --progress=false > "$INSTALL_LOG" 2>&1 || (tail -n 200 "$INSTALL_LOG" >&2; echo 'npm ci failed; see install.log' >&2; exit 31)
  else
    npm i --no-audit --progress=false > "$INSTALL_LOG" 2>&1 || (tail -n 200 "$INSTALL_LOG" >&2; echo 'npm install failed; see install.log' >&2; exit 32)
  fi
fi
# Verify core packages can be resolved
node -e "try{ require.resolve('react'); require.resolve('react-dom'); try{ require.resolve('react-scripts'); }catch(e){} process.exit(0);}catch(e){ console.error('module resolution failed:',e.message); process.exit(33)}" || (tail -n 200 "$INSTALL_LOG" >&2; echo 'core packages missing or not resolvable; see install.log' >&2; exit 34)
# npm ls to detect broken installs (non-fatal parse but fail on missing)
npm ls react react-dom react-scripts --depth=0 > "$INSTALL_LOG" 2>&1 || (tail -n 200 "$INSTALL_LOG" >&2; echo 'npm ls indicates issues; see install.log' >&2; exit 35)
