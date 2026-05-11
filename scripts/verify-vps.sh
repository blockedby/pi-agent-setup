#!/usr/bin/env bash
set -euo pipefail

TARGET_HOST="${TARGET_HOST:-nl-2-nvme}"
ssh "$TARGET_HOST" bash -s <<'REMOTE'
set -euo pipefail
export PATH="/root/.vite-plus/bin:$PATH"

echo '== vite/node/npm/pi =='
/root/.vite-plus/bin/node --version
/root/.vite-plus/bin/npm --version
/root/.vite-plus/bin/pi --version

echo '== pi files =='
test -f /root/.pi/agent/settings.json
test -d /root/.pi/agent/agents
find /root/.pi/agent/agents -maxdepth 1 -type f -name '*.md' -printf '%f\n' | sort

echo '== pi packages =='
/root/.vite-plus/bin/pi list | sed -n '1,160p'

echo '== smoke =='
timeout "${PI_SMOKE_TIMEOUT_SECONDS:-900}" /root/.vite-plus/bin/pi --no-session --mode text -p 'Say OK and exit.' | tail -n 40
REMOTE
