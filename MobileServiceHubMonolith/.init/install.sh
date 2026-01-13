#!/usr/bin/env bash
set -euo pipefail
WORKSPACE="/home/kavia/workspace/code-generation/mobile-service-hub-41952-42033/MobileServiceHubMonolith"
[ -d "$WORKSPACE" ] || { echo "workspace missing: $WORKSPACE" >&2; exit 2; }
cd "$WORKSPACE"
# persist env for login shells atomically
PROFILE=/etc/profile.d/project_node_env.sh
TMP_PROFILE=/tmp/project_node_env.sh.$$ 
sudo bash -lc "cat > $TMP_PROFILE <<'EOF'
# auto-generated: ensure node env for non-interactive CI runs
export NODE_ENV=development
export CI=true
# ensure npm global bin on PATH for interactive logins
if [ -n "$(npm bin -g 2>/dev/null || true)" ]; then
  case ":$PATH:" in
    *:$(npm bin -g):*) ;; 
    *) export PATH="$(npm bin -g):$PATH" ;;
  esac
fi
EOF
sudo mv -f $TMP_PROFILE $PROFILE && sudo chmod 0644 $PROFILE || true"

LOG="/tmp/deps-install-$(date +%s).log"
# record versions for debugging
{ echo "node: $(node -v 2>/dev/null || echo 'missing')"; echo "npm: $(npm -v 2>/dev/null || echo 'missing')"; echo "yarn: $(command -v yarn >/dev/null 2>&1 && yarn -v || echo 'absent')"; } >"$LOG" 2>&1 || true

# helper: run npm ci with flags and streaming logs
npm_ci(){ npm ci --no-audit --no-fund --prefer-offline --silent; }
npm_install(){ npm install --no-audit --no-fund --silent; }

echo "Installing dependencies..." >>"$LOG" 2>&1
# ensure CI env for non-interactive installs
export CI=true

# detect package manifest and lockfiles
HAS_YARN_LOCK=[ -f yarn.lock ] && echo yes || echo no

# attempt installer with retry-once for transient failures
attempt_install(){
  local attempt=0; local max=1
  while true; do
    attempt=$((attempt+1))
    # prefer yarn when yarn.lock present and yarn available
    if [ -f yarn.lock ] && command -v yarn >/dev/null 2>&1; then
      # try yarn --frozen-lockfile
      echo "trying yarn --frozen-lockfile (attempt $attempt)" >>"$LOG" 2>&1
      if yarn --frozen-lockfile --non-interactive --silent >>"$LOG" 2>&1; then return 0; fi
      echo "yarn failed (attempt $attempt)" >>"$LOG" 2>&1
      # fallthrough to npm fallback
    fi

    if [ -f package-lock.json ]; then
      echo "trying npm ci (attempt $attempt)" >>"$LOG" 2>&1
      if npm_ci >>"$LOG" 2>&1; then return 0; fi
      echo "npm ci failed (attempt $attempt)" >>"$LOG" 2>&1
    else
      echo "trying npm install (attempt $attempt)" >>"$LOG" 2>&1
      if npm_install >>"$LOG" 2>&1; then return 0; fi
      echo "npm install failed (attempt $attempt)" >>"$LOG" 2>&1
    fi

    if [ "$attempt" -le "$max" ]; then
      echo "transient failure, retrying..." >>"$LOG" 2>&1
      sleep 1
      continue
    else
      return 1
    fi
  done
}

if ! attempt_install; then
  echo "Dependency installation failed. Log follows:" >&2
  sed -n '1,200p' "$LOG" >&2 || true
  echo "--- last 200 lines ---" >&2
  tail -n 200 "$LOG" >&2 || true
  exit 10
fi

# validate react/react-dom declared in package.json
node -e "try{const p=require('./package.json'); const deps=Object.assign({},p.dependencies||{},p.devDependencies||{}); if(!deps.react||!deps['react-dom']){console.error('react/react-dom not declared'); process.exit(11);} }catch(e){console.error('package.json read error',e); process.exit(13); }" 2>>"$LOG" || { sed -n '1,200p' "$LOG" >&2 || true; exit 11; }

# validate react/react-dom resolvable after install
node -e "try{require.resolve('react'); require.resolve('react-dom'); process.exit(0);}catch(e){console.error('react/react-dom not installed',e); process.exit(12);}" 2>>"$LOG" || { echo 'react/react-dom not installed after install' >&2; sed -n '1,200p' "$LOG" >&2 || true; exit 12; }

echo "dependencies installed and basic validation passed" >>"$LOG" 2>&1
exit 0
