#!/usr/bin/env bash
set -euo pipefail

TARGET_HOST="${TARGET_HOST:-nl-2-nvme}"
REMOTE_USER_HOME="${REMOTE_USER_HOME:-/root}"
PI_VERSION="${PI_VERSION:-0.74.0}"
NPM_BIN="$REMOTE_USER_HOME/.vite-plus/bin/npm"
PI_BIN="$REMOTE_USER_HOME/.vite-plus/bin/pi"
TMP_DIR="/tmp/pi-agent-setup.$$"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ssh "$TARGET_HOST" "rm -rf '$TMP_DIR' && mkdir -p '$TMP_DIR/agents' '$TMP_DIR/settings'"
rsync -a "$repo_root/agents/" "$TARGET_HOST:$TMP_DIR/agents/"
rsync -a "$repo_root/settings/pi-settings.vps.json" "$TARGET_HOST:$TMP_DIR/settings/pi-settings.vps.json"

ssh "$TARGET_HOST" bash -s -- "$REMOTE_USER_HOME" "$PI_VERSION" "$NPM_BIN" "$PI_BIN" "$TMP_DIR" <<'REMOTE'
set -euo pipefail
REMOTE_USER_HOME="$1"
PI_VERSION="$2"
NPM_BIN="$3"
PI_BIN="$4"
TMP_DIR="$5"

if [ ! -x "$NPM_BIN" ]; then
  echo "Vite+ npm not found at $NPM_BIN; install Vite+ first." >&2
  exit 1
fi

"$NPM_BIN" install -g "@earendil-works/pi-coding-agent@$PI_VERSION"

mkdir -p "$REMOTE_USER_HOME/.pi/agent/agents"
if [ -f "$REMOTE_USER_HOME/.pi/agent/settings.json" ]; then
  cp -a "$REMOTE_USER_HOME/.pi/agent/settings.json" "$REMOTE_USER_HOME/.pi/agent/settings.json.bak.$(date -u +%Y%m%dT%H%M%SZ)"
fi
install -m 0644 "$TMP_DIR/settings/pi-settings.vps.json" "$REMOTE_USER_HOME/.pi/agent/settings.json"
install -m 0644 "$TMP_DIR/agents/"*.md "$REMOTE_USER_HOME/.pi/agent/agents/"
chmod 700 "$REMOTE_USER_HOME/.pi" "$REMOTE_USER_HOME/.pi/agent" "$REMOTE_USER_HOME/.pi/agent/agents"
chmod 600 "$REMOTE_USER_HOME/.pi/agent/agents/"*.md "$REMOTE_USER_HOME/.pi/agent/settings.json"

rm -rf "$TMP_DIR"
"$PI_BIN" --version
REMOTE
