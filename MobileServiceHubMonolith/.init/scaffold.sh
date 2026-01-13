#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/mobile-service-hub-41952-42033/MobileServiceHubMonolith"
[ -d "$WORKSPACE" ] || { echo "workspace missing: $WORKSPACE" >&2; exit 2; }
cd "$WORKSPACE"
# atomic /etc/profile.d write (requires sudo)
PROFILE=/etc/profile.d/dev-env.sh
TMP_PROFILE=/tmp/dev-env.sh.tmp
echo 'export NODE_ENV=development' > "$TMP_PROFILE"
echo 'export CI=true' >> "$TMP_PROFILE"
echo 'export PATH="$PATH:$(npm bin -g 2>/dev/null || echo /usr/local/bin)"' >> "$TMP_PROFILE"
if [ -f "$PROFILE" ]; then sudo cp "$PROFILE" "$PROFILE.bak"; fi
sudo mv -f "$TMP_PROFILE" "$PROFILE" && sudo chmod 644 "$PROFILE" || { echo "failed to install profile" >&2; exit 3; }
# ensure CI in current env for non-interactive tools
export CI=true
# detect emptiness
NON_EMPTY=0
if [ -n "$(ls -A 2>/dev/null)" ]; then NON_EMPTY=1; fi
# scaffold only if package.json missing
if [ ! -f package.json ]; then
  if [ $NON_EMPTY -eq 1 ] && [ ! -f .scaffold-allow ]; then
    echo "workspace non-empty and no .scaffold-allow marker; skipping scaffold to avoid overwriting" >&2
    exit 6
  fi
  if [ $NON_EMPTY -eq 1 ] && [ -f .scaffold-allow ]; then
    TAR="/tmp/$(basename "$WORKSPACE")-backup-$(date +%s).tar.gz"
    tar -czf "$TAR" . || { echo "backup failed" >&2; exit 7; }
  fi
  # prefer preinstalled create-react-app; use npx reliably
  # ensure non-interactive and npm-based
  if command -v create-react-app >/dev/null 2>&1; then
    npx --yes create-react-app@latest . --use-npm --silent || true
  else
    npx --yes create-react-app@latest . --use-npm --silent || true
  fi
fi
# detect vite / ts
IS_VITE=0
IS_TS=0
if [ -f package.json ]; then
  node -e "try{const p=require('./package.json'); const d=Object.assign({},p.dependencies||{},p.devDependencies||{}); if(d.vite) console.log(1);}catch(e){}" 2>/dev/null | grep -q 1 && IS_VITE=1 || true
fi
([ -f vite.config.js ] || [ -f vite.config.ts ]) && IS_VITE=1 || true
[ -f tsconfig.json ] && IS_TS=1 || true
# helper to set package.json scripts idempotently
set_script(){ local name=$1; local val=$2
  if command -v npm >/dev/null 2>&1 && npm --version >/dev/null 2>&1 && npm --version | awk -F. '{if($1>=7)exit 0; exit 1}'; then
    npm pkg set "scripts.${name}=${val}" >/dev/null || true
  else
    if command -v jq >/dev/null 2>&1 && [ -f package.json ]; then
      tmp=$(mktemp)
      jq --arg v "$val" --arg name "$name" '.scripts |= (. // {}) | .scripts[$name] = $v' package.json >"$tmp" && mv "$tmp" package.json || true
    fi
  fi
}
# add default scripts if missing (do not overwrite existing)
if [ -f package.json ]; then
  node -e "try{const p=require('./package.json'); const s=p.scripts||{}; if(!s.start) console.log('addStart');}catch(e){}" 2>/dev/null | grep -q addStart && {
    if [ "$IS_VITE" -eq 1 ]; then set_script start "vite"; else set_script start "BROWSER=none react-scripts start"; fi
  } || true
  node -e "try{const p=require('./package.json'); const s=p.scripts||{}; if(!s.build) console.log('addBuild');}catch(e){}" 2>/dev/null | grep -q addBuild && {
    if [ "$IS_VITE" -eq 1 ]; then set_script build "vite build"; else set_script build "react-scripts build"; fi
  } || true
  node -e "try{const p=require('./package.json'); const s=p.scripts||{}; if(!s.test) console.log('addTest');}catch(e){}" 2>/dev/null | grep -q addTest && {
    node -e "try{const p=require('./package.json'); const deps=Object.assign({},p.dependencies||{},p.devDependencies||{}); if(deps['react-scripts']) console.log('rs');}catch(e){}" 2>/dev/null | grep -q rs && set_script test "react-scripts test --watchAll=false --passWithNoTests" || set_script test "jest --runInBand"
  } || true
  node -e "try{const p=require('./package.json'); const s=p.scripts||{}; if(!s['mock-server']) console.log('addMock');}catch(e){}" 2>/dev/null | grep -q addMock && set_script "mock-server" "node ./scripts/mock-server.js" || true
fi
# ensure mock data and server script exist
mkdir -p src/mocks && [ -f src/mocks/data.json ] || echo '{"status":"ok"}' > src/mocks/data.json
mkdir -p scripts
if [ ! -f scripts/mock-server.js ]; then
  cat > scripts/mock-server.js <<'S'
const http = require('http');
const fs = require('fs');
const port = process.env.PORT || 4000;
let data = {status:'ok'};
try{data = JSON.parse(fs.readFileSync('src/mocks/data.json','utf8'));}catch(e){}
http.createServer((req,res)=>{res.writeHead(200,{'Content-Type':'application/json'});res.end(JSON.stringify(data));}).listen(port);
S
  chmod +x scripts/mock-server.js
fi
# final validation: ensure package.json exists
if [ ! -f package.json ]; then
  echo "scaffold attempted but package.json still missing" >&2
  exit 8
fi
exit 0
