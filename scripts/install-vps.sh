#!/usr/bin/env bash
set -euo pipefail

TARGET_HOST="${TARGET_HOST:-nl-2-nvme}"
REMOTE_USER_HOME="${REMOTE_USER_HOME:-/root}"
PI_VERSION="${PI_VERSION:-0.74.0}"
CODEX_VERSION="${CODEX_VERSION:-0.130.0}"
VP_BIN="$REMOTE_USER_HOME/.vite-plus/bin/vp"
NPM_BIN="$REMOTE_USER_HOME/.vite-plus/bin/npm"
PI_BIN="$REMOTE_USER_HOME/.vite-plus/bin/pi"
CODEX_BIN="$REMOTE_USER_HOME/.vite-plus/bin/codex"
TMP_DIR="/tmp/pi-agent-setup.$$"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ssh "$TARGET_HOST" "rm -rf '$TMP_DIR' && mkdir -p '$TMP_DIR/agents' '$TMP_DIR/settings' '$TMP_DIR/skills'"
rsync -a "$repo_root/agents/" "$TARGET_HOST:$TMP_DIR/agents/"
rsync -a "$repo_root/settings/pi-settings.vps.json" "$TARGET_HOST:$TMP_DIR/settings/pi-settings.vps.json"
rsync -a "$repo_root/skills/" "$TARGET_HOST:$TMP_DIR/skills/"

ssh "$TARGET_HOST" bash -s -- "$REMOTE_USER_HOME" "$PI_VERSION" "$CODEX_VERSION" "$VP_BIN" "$NPM_BIN" "$PI_BIN" "$CODEX_BIN" "$TMP_DIR" <<'REMOTE'
set -euo pipefail
REMOTE_USER_HOME="$1"
PI_VERSION="$2"
CODEX_VERSION="$3"
VP_BIN="$4"
NPM_BIN="$5"
PI_BIN="$6"
CODEX_BIN="$7"
TMP_DIR="$8"

if [ ! -x "$NPM_BIN" ]; then
  echo "Vite+ npm not found at $NPM_BIN; install Vite+ first." >&2
  exit 1
fi
if [ ! -x "$VP_BIN" ]; then
  echo "Vite+ vp not found at $VP_BIN; install Vite+ first." >&2
  exit 1
fi

"$VP_BIN" install -g "@earendil-works/pi-coding-agent@$PI_VERSION"
"$VP_BIN" install -g "@openai/codex@$CODEX_VERSION"

mkdir -p "$REMOTE_USER_HOME/.pi/agent/agents" "$REMOTE_USER_HOME/.pi/agent/skills"
if [ -f "$REMOTE_USER_HOME/.pi/agent/settings.json" ]; then
  cp -a "$REMOTE_USER_HOME/.pi/agent/settings.json" "$REMOTE_USER_HOME/.pi/agent/settings.json.bak.$(date -u +%Y%m%dT%H%M%SZ)"
fi
install -m 0644 "$TMP_DIR/settings/pi-settings.vps.json" "$REMOTE_USER_HOME/.pi/agent/settings.json"
install -m 0644 "$TMP_DIR/agents/"*.md "$REMOTE_USER_HOME/.pi/agent/agents/"
rsync -a "$TMP_DIR/skills/" "$REMOTE_USER_HOME/.pi/agent/skills/"
chmod 700 "$REMOTE_USER_HOME/.pi" "$REMOTE_USER_HOME/.pi/agent" "$REMOTE_USER_HOME/.pi/agent/agents" "$REMOTE_USER_HOME/.pi/agent/skills"
chmod 600 "$REMOTE_USER_HOME/.pi/agent/agents/"*.md "$REMOTE_USER_HOME/.pi/agent/settings.json"
find "$REMOTE_USER_HOME/.pi/agent/skills" -type d -exec chmod 700 {} +
find "$REMOTE_USER_HOME/.pi/agent/skills" -type f -exec chmod 600 {} +

rm -rf "$TMP_DIR"
"$PI_BIN" --version
"$CODEX_BIN" --version
REMOTE
