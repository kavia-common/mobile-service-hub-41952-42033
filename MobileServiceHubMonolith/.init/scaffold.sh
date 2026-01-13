#!/usr/bin/env bash
set -euo pipefail
# Step: Project scaffolding with Vite + React (ESM) and package-lock creation
WORKSPACE="/home/kavia/workspace/code-generation/mobile-service-hub-41952-42033/MobileServiceHubMonolith"
# validate workspace
[ -d "$WORKSPACE" ] || { echo "workspace missing: $WORKSPACE" >&2; exit 2; }
cd "$WORKSPACE"
# check node/npm
NODE_BIN=$(command -v node || true)
NPM_BIN=$(command -v npm || true)
if [ -z "$NODE_BIN" ] || [ -z "$NPM_BIN" ]; then
  echo "node or npm not found on PATH" >&2
  exit 3
fi
NODE_VERSION=$($NODE_BIN -v | sed 's/^v//')
# require Node >=18
REQUIRED_MAJOR=18
MAJOR=${NODE_VERSION%%.*}
if [ "${MAJOR:-0}" -lt "$REQUIRED_MAJOR" ]; then
  echo "node >= $REQUIRED_MAJOR required, found $NODE_VERSION" >&2
  exit 4
fi
# compute npm global bin and write /etc/profile.d snippet idempotently
NPM_GBIN=$($NPM_BIN bin -g)
PROFILE_FILE=/etc/profile.d/npm_gbin.sh
SNIPPET="if [ -d '$NPM_GBIN' ] && ! echo \"\$PATH\" | /bin/grep -q -F '$NPM_GBIN'; then PATH='$NPM_GBIN':\"\$PATH\"; export PATH; fi"
# write single-quoted file content to avoid premature expansion; requires sudo to write to /etc/profile.d
if [ ! -f "$PROFILE_FILE" ]; then
  printf '%s\n' "#!/usr/bin/env sh" "$SNIPPET" > /tmp/npm_gbin.sh
  sudo mv /tmp/npm_gbin.sh "$PROFILE_FILE" || { echo "failed to write $PROFILE_FILE" >&2; exit 5; }
  sudo chmod 644 "$PROFILE_FILE"
fi
# export session env vars if not set
: "${NODE_ENV:=}">	mp >/dev/null 2>&1 || true
if [ -z "${NODE_ENV:-}" ]; then export NODE_ENV=development; fi
if [ -z "${API_BASE_URL:-}" ]; then export API_BASE_URL='http://localhost:3000'; fi
# create scaffold files (idempotent - skip existing files except public/mock-api.json which is written)
mkdir -p src public
if [ ! -f package.json ]; then
  cat > package.json <<'JSON'
{
  "name": "mobile-service-hub-monolith",
  "version": "0.1.0",
  "private": true,
  "dependencies": {
    "react": "18.2.0",
    "react-dom": "18.2.0"
  },
  "devDependencies": {
    "vite": "5.2.0",
    "@vitejs/plugin-react": "5.0.0",
    "react-test-renderer": "18.2.0",
    "jest": "29.6.0",
    "babel-jest": "29.6.0",
    "@babel/preset-react": "7.22.5"
  },
  "scripts": {
    "start": "vite",
    "build": "vite build",
    "test": "jest --runInBand"
  }
}
JSON
fi
if [ ! -f src/main.jsx ]; then
  cat > src/main.jsx <<'JSX'
import React from 'react'
import { createRoot } from 'react-dom/client'
import App from './App'
createRoot(document.getElementById('root')).render(<App />)
JSX
fi
if [ ! -f src/App.jsx ]; then
  cat > src/App.jsx <<'JSX'
import React from 'react'
export default function App(){ return <div>Mobile Service Hub - Dev</div> }
JSX
fi
if [ ! -f index.html ]; then
  cat > index.html <<'HTML'
<!doctype html>
<html>
  <head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1.0"><title>MobileServiceHub</title></head>
  <body><div id="root"></div><script type="module" src="/src/main.jsx"></script></body>
</html>
HTML
fi
if [ ! -f vite.config.js ]; then
  cat > vite.config.js <<'VITE'
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
export default defineConfig({plugins:[react()]})
VITE
fi
if [ ! -f babel.config.js ]; then
  cat > babel.config.js <<'BABEL'
module.exports = { presets: [['@babel/preset-react', { runtime: 'automatic' }]] };
BABEL
fi
# write/overwrite mock fixture (non-critical)
cat > public/mock-api.json <<'JSON'
{ "services": [{"id":1,"name":"mock-service"}] }
JSON
# create package-lock.json if missing using npm i --package-lock-only
if [ ! -f package-lock.json ]; then
  if ! npm i --package-lock-only --no-audit --no-fund >/dev/null 2>&1; then
    echo "failed to create package-lock.json" >&2
    exit 6
  fi
fi
exit 0
