#!/usr/bin/env bash
set -euo pipefail
export NODE_ENV=development; export HOST=0.0.0.0; export PORT=${PORT:-3000}
WORKSPACE="/home/kavia/workspace/code-generation/mobile-service-hub-41952-42033/MobileServiceHubMonolith"
cd "$WORKSPACE"
[ -f package.json ] && { echo "package.json exists, skipping scaffold"; exit 0; }
# ensure empty directory before running CRA to avoid overwrite
if [ "$(find . -maxdepth 1 ! -name '.' ! -name '..' -print | wc -l)" -gt 0 ]; then
  echo "Workspace is not empty and no package.json present; refusing to run CRA to avoid overwrite" >&2
  exit 5
fi
if command -v create-react-app >/dev/null 2>&1; then
  # prefer CRA but run visibly so failures surface; dependency install is deferred
  create-react-app . --use-npm || { echo "create-react-app scaffold failed" >&2; exit 6; }
  # verify package.json created
  [ -f package.json ] || { echo "CRA did not produce package.json" >&2; exit 7; }
  exit 0
fi
# Fallback minimal project (no install here). Use atomic writes via temp file then mv.
TMP=$(mktemp)
cat > "$TMP" <<'JSON'
{
  "name": "mobile-service-hub-monolith",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "start": "react-scripts start",
    "build": "react-scripts build",
    "test": "react-scripts test --watchAll=false"
  },
  "dependencies": {
    "react": "^18.0.0",
    "react-dom": "^18.0.0",
    "react-scripts": "^5.0.0"
  }
}
JSON
mv "$TMP" package.json
mkdir -p public src
TMP_HTML=$(mktemp)
cat > "$TMP_HTML" <<'HTML'
<!doctype html><html><head><meta charset="utf-8"><title>MobileServiceHubMonolith</title></head><body><div id="root"></div></body></html>
HTML
mv "$TMP_HTML" public/index.html
TMP_JS=$(mktemp)
cat > "$TMP_JS" <<'JS'
import React from 'react';
import { createRoot } from 'react-dom/client';
function App(){ return React.createElement('div',null,'Hello MobileServiceHubMonolith'); }
createRoot(document.getElementById('root')).render(React.createElement(App));
JS
mv "$TMP_JS" src/index.js
exit 0
