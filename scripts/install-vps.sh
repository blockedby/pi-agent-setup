#!/usr/bin/env bash
set -euo pipefail

TARGET_HOST="${TARGET_HOST:-nl-2-nvme}"
REMOTE_USER_HOME="${REMOTE_USER_HOME:-}"
PI_VERSION="${PI_VERSION:-0.74.0}"
CODEX_VERSION="${CODEX_VERSION:-0.130.0}"
TMP_DIR="/tmp/pi-agent-setup.$$"

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

ssh "$TARGET_HOST" "rm -rf '$TMP_DIR' && mkdir -p '$TMP_DIR/agents' '$TMP_DIR/settings' '$TMP_DIR/skills'"
rsync -a "$repo_root/agents/" "$TARGET_HOST:$TMP_DIR/agents/"
rsync -a "$repo_root/settings/pi-settings.vps.json" "$TARGET_HOST:$TMP_DIR/settings/pi-settings.vps.json"
rsync -a "$repo_root/skills/" "$TARGET_HOST:$TMP_DIR/skills/"

ssh "$TARGET_HOST" bash -s -- "$REMOTE_USER_HOME" "$PI_VERSION" "$CODEX_VERSION" "$TMP_DIR" <<'REMOTE'
set -euo pipefail
REQUESTED_REMOTE_USER_HOME="$1"
PI_VERSION="$2"
CODEX_VERSION="$3"
TMP_DIR="$4"

if [ -n "$REQUESTED_REMOTE_USER_HOME" ]; then
  if [ -d "$REQUESTED_REMOTE_USER_HOME" ]; then
    REMOTE_USER_HOME="$REQUESTED_REMOTE_USER_HOME"
  else
    REMOTE_USER_HOME="/root"
  fi
elif [ -n "${HOME:-}" ] && [ -d "$HOME" ]; then
  REMOTE_USER_HOME="$HOME"
else
  REMOTE_USER_HOME="/root"
fi

VP_BIN="$REMOTE_USER_HOME/.vite-plus/bin/vp"
NPM_BIN="$REMOTE_USER_HOME/.vite-plus/bin/npm"
PI_BIN="$REMOTE_USER_HOME/.vite-plus/bin/pi"
CODEX_BIN="$REMOTE_USER_HOME/.vite-plus/bin/codex"
AGENT_DIR="$REMOTE_USER_HOME/.pi/agent"

if [ ! -x "$NPM_BIN" ]; then
  echo "Vite+ npm not found at $NPM_BIN; install Vite+ first or set REMOTE_USER_HOME to the home containing .vite-plus." >&2
  exit 1
fi
if [ ! -x "$VP_BIN" ]; then
  echo "Vite+ vp not found at $VP_BIN; install Vite+ first or set REMOTE_USER_HOME to the home containing .vite-plus." >&2
  exit 1
fi

"$VP_BIN" install -g "@earendil-works/pi-coding-agent@$PI_VERSION"
"$VP_BIN" install -g "@openai/codex@$CODEX_VERSION"

mkdir -p "$AGENT_DIR/agents" "$AGENT_DIR/skills"
if [ -f "$AGENT_DIR/settings.json" ]; then
  cp -a "$AGENT_DIR/settings.json" "$AGENT_DIR/settings.json.bak.$(date -u +%Y%m%dT%H%M%SZ)"
fi
install -m 0644 "$TMP_DIR/settings/pi-settings.vps.json" "$AGENT_DIR/settings.json"

# Remove known renamed/disabled agents and chains so old executable files do not
# survive across upgrades in ~/.pi/agent/agents.
for stale in \
  tdd-coder.md \
  implementer.md \
  failure-classifier.md \
  aad-test-auditor.md \
  aad-reviewer.md \
  quinn-validator.md \
  aad-parallel-investigation.chain.md; do
  rm -f "$AGENT_DIR/agents/$stale" "$REMOTE_USER_HOME/.agents/$stale"
done

install -m 0644 "$TMP_DIR/agents/"*.md "$AGENT_DIR/agents/"
rsync -a --delete "$TMP_DIR/skills/" "$AGENT_DIR/skills/"

BROWSER_CHROME_SKILL_DIR="$AGENT_DIR/skills/browser-chrome"
if [ -f "$BROWSER_CHROME_SKILL_DIR/scripts/mcp.sh" ]; then
  chmod +x "$BROWSER_CHROME_SKILL_DIR/scripts/"*.sh
  python3 - "$AGENT_DIR/mcp.json" "$BROWSER_CHROME_SKILL_DIR/scripts/mcp.sh" <<'PY'
import json
import sys
from pathlib import Path

mcp_path = Path(sys.argv[1])
command = sys.argv[2]
if mcp_path.exists():
    with mcp_path.open() as f:
        data = json.load(f)
else:
    data = {}
servers = data.setdefault("mcpServers", {})
common_env = {"CHROME_DEVTOOLS_MCP_NO_UPDATE_CHECKS": "1"}
servers["browser-chrome-headed"] = {
    "command": command,
    "args": ["headed"],
    "lifecycle": "lazy",
    "env": common_env,
}
servers["browser-chrome-headless"] = {
    "command": command,
    "args": ["headless"],
    "lifecycle": "lazy",
    "idleTimeout": 1,
    "env": common_env,
}
mcp_path.parent.mkdir(parents=True, exist_ok=True)
if mcp_path.exists():
    backup = mcp_path.with_suffix(mcp_path.suffix + ".bak")
    backup.write_text(mcp_path.read_text())
with mcp_path.open("w") as f:
    json.dump(data, f, indent=2)
    f.write("\n")
PY
fi

chmod 700 "$REMOTE_USER_HOME/.pi" "$AGENT_DIR" "$AGENT_DIR/agents" "$AGENT_DIR/skills"
chmod 600 "$AGENT_DIR/agents/"*.md "$AGENT_DIR/settings.json"
find "$AGENT_DIR/skills" -type d -exec chmod 700 {} +
find "$AGENT_DIR/skills" -type f -exec chmod 600 {} +
find "$AGENT_DIR/skills/browser-chrome/scripts" -type f -name '*.sh' -exec chmod 700 {} + 2>/dev/null || true
if [ -f "$AGENT_DIR/mcp.json" ]; then
  chmod 600 "$AGENT_DIR/mcp.json"
fi

rm -rf "$TMP_DIR"
echo "Installed Pi agent setup under $AGENT_DIR"
"$PI_BIN" --version
"$CODEX_BIN" --version
REMOTE
