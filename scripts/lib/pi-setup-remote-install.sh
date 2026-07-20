#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=setup-common.sh
source "$repo_root/scripts/lib/setup-common.sh"

TARGET_HOST="${TARGET_HOST:-}"
REMOTE_USER_HOME="${REMOTE_USER_HOME:-}"
PI_VERSION="${PI_VERSION:-latest}"
CODEX_VERSION="${CODEX_VERSION:-latest}"
PI_SETTINGS_FILE="${PI_SETTINGS_FILE:-settings/pi-settings.example.json}"
TMP_DIR="/tmp/pi-agent-setup.$$"

if [ -z "$TARGET_HOST" ]; then
  echo "TARGET_HOST is required, for example: TARGET_HOST=<host> $0" >&2
  exit 2
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
settings_path="$repo_root/$PI_SETTINGS_FILE"
if [ ! -f "$settings_path" ]; then
  echo "PI_SETTINGS_FILE not found: $PI_SETTINGS_FILE" >&2
  echo "Use settings/pi-settings.example.json or an ignored settings/*.local.json copy." >&2
  exit 2
fi

cleanup_remote() {
  ssh "$TARGET_HOST" "rm -rf '$TMP_DIR'" >/dev/null 2>&1 || true
}
trap cleanup_remote EXIT

ssh "$TARGET_HOST" "rm -rf '$TMP_DIR' && mkdir -p '$TMP_DIR/agents' '$TMP_DIR/extensions' '$TMP_DIR/settings' '$TMP_DIR/skills' '$TMP_DIR/scripts/lib'"
rsync -a "$repo_root/APPEND_SYSTEM.md" "$TARGET_HOST:$TMP_DIR/APPEND_SYSTEM.md"
rsync -a "$repo_root/scripts/lib/runtime-paths.sh" "$TARGET_HOST:$TMP_DIR/scripts/lib/runtime-paths.sh"
rsync -a "$repo_root/scripts/lib/setup-common.sh" "$TARGET_HOST:$TMP_DIR/scripts/lib/setup-common.sh"
rsync -a "$repo_root/scripts/lib/config-json.py" "$TARGET_HOST:$TMP_DIR/scripts/lib/config-json.py"
rsync -a "$repo_root/agents/" "$TARGET_HOST:$TMP_DIR/agents/"
rsync -a "$repo_root/extensions/" "$TARGET_HOST:$TMP_DIR/extensions/"
rsync -a "$settings_path" "$TARGET_HOST:$TMP_DIR/settings/settings.json"
rsync -a "$repo_root/settings/pi-subagents.config.json" "$TARGET_HOST:$TMP_DIR/settings/pi-subagents.config.json"
rsync -a "$repo_root/skills/" "$TARGET_HOST:$TMP_DIR/skills/"

ssh "$TARGET_HOST" bash -s -- "$REMOTE_USER_HOME" "$PI_VERSION" "$CODEX_VERSION" "$TMP_DIR" <<'REMOTE'
set -euo pipefail
REQUESTED_REMOTE_USER_HOME="$1"
PI_VERSION="$2"
CODEX_VERSION="$3"
TMP_DIR="$4"
# shellcheck source=setup-common.sh
source "$TMP_DIR/scripts/lib/setup-common.sh"

REMOTE_USER_HOME="$(pi_setup_resolve_home "$REQUESTED_REMOTE_USER_HOME")"

VP_BIN="$REMOTE_USER_HOME/.vite-plus/bin/vp"
NPM_BIN="$REMOTE_USER_HOME/.vite-plus/bin/npm"
PI_BIN="$REMOTE_USER_HOME/.local/bin/pi"
CODEX_BIN="$REMOTE_USER_HOME/.vite-plus/bin/codex"
AGENT_DIR="$REMOTE_USER_HOME/.pi/agent"
# shellcheck source=lib/runtime-paths.sh
source "$TMP_DIR/scripts/lib/runtime-paths.sh"
export PATH="$REMOTE_USER_HOME/.local/bin:$REMOTE_USER_HOME/.vite-plus/bin:$PATH"

if [ ! -x "$NPM_BIN" ]; then
  echo "Vite+ npm not found at $NPM_BIN; install Vite+ first or set REMOTE_USER_HOME to the home containing .vite-plus." >&2
  exit 1
fi
if [ ! -x "$VP_BIN" ]; then
  echo "Vite+ vp not found at $VP_BIN; install Vite+ first or set REMOTE_USER_HOME to the home containing .vite-plus." >&2
  exit 1
fi

mkdir -p "$REMOTE_USER_HOME/.local"
"$NPM_BIN" install -g --prefix "$REMOTE_USER_HOME/.local" "@earendil-works/pi-coding-agent@$PI_VERSION"
"$VP_BIN" install -g "@openai/codex@$CODEX_VERSION"
configure_pi_bash_path "$REMOTE_USER_HOME"

mkdir -p "$AGENT_DIR/agents" "$AGENT_DIR/extensions" "$AGENT_DIR/extensions/subagent" "$AGENT_DIR/skills"
if [ -f "$AGENT_DIR/settings.json" ]; then
  cp -a "$AGENT_DIR/settings.json" "$AGENT_DIR/settings.json.bak.$(date -u +%Y%m%dT%H%M%SZ)"
fi
install -m 0644 "$TMP_DIR/settings/settings.json" "$AGENT_DIR/settings.json"
install -m 0644 "$TMP_DIR/settings/pi-subagents.config.json" "$AGENT_DIR/extensions/subagent/config.json"
install -m 0644 "$TMP_DIR/APPEND_SYSTEM.md" "$AGENT_DIR/APPEND_SYSTEM.md"

# Remove known renamed/disabled agents so old executable files do not
# survive across upgrades in ~/.pi/agent/agents.
for stale in \
  tdd-coder.md \
  implementer.md \
  failure-classifier.md \
  aad-test-auditor.md \
  aad-reviewer.md \
  quinn-validator.md; do
  rm -f "$AGENT_DIR/agents/$stale" "$REMOTE_USER_HOME/.agents/$stale"
done

install -m 0644 "$TMP_DIR/agents/"*.md "$AGENT_DIR/agents/"
install -m 0644 "$TMP_DIR/extensions/"*.ts "$AGENT_DIR/extensions/"
rsync -a --delete "$TMP_DIR/skills/" "$AGENT_DIR/skills/"

MAGIC_MCP_CONFIG="$AGENT_DIR/skills/21st-magic-mcp/mcp/21st-magic.mcp.json"
if [ -f "$MAGIC_MCP_CONFIG" ]; then
  mkdir -p "$REMOTE_USER_HOME/.cache/21st-magic-mcp/test-results"
  python3 "$TMP_DIR/scripts/lib/config-json.py" merge-mcp "$AGENT_DIR/mcp.json" "$MAGIC_MCP_CONFIG" remote-install
fi

BROWSER_CHROME_SKILL_DIR="$AGENT_DIR/skills/browser-chrome"
if [ -f "$BROWSER_CHROME_SKILL_DIR/scripts/mcp.sh" ]; then
  chmod +x "$BROWSER_CHROME_SKILL_DIR/scripts/"*.sh
  python3 "$TMP_DIR/scripts/lib/config-json.py" browser-chrome-mcp "$AGENT_DIR/mcp.json" "$BROWSER_CHROME_SKILL_DIR/scripts/mcp.sh"
fi

chmod 700 "$REMOTE_USER_HOME/.pi" "$AGENT_DIR" "$AGENT_DIR/agents" "$AGENT_DIR/extensions" "$AGENT_DIR/skills"
chmod 600 "$AGENT_DIR/APPEND_SYSTEM.md" "$AGENT_DIR/agents/"*.md "$AGENT_DIR/extensions/"*.ts "$AGENT_DIR/settings.json"
find "$AGENT_DIR/skills" -type d -exec chmod 700 {} +
find "$AGENT_DIR/skills" -type f -exec chmod 600 {} +
find "$AGENT_DIR/skills/browser-chrome/scripts" -type f -name '*.sh' -exec chmod 700 {} + 2>/dev/null || true
if [ -f "$AGENT_DIR/mcp.json" ]; then
  chmod 600 "$AGENT_DIR/mcp.json"
fi

rm -rf "$TMP_DIR"
echo "Installed Pi agent setup under $AGENT_DIR"
echo "Global append system prompt installed at $AGENT_DIR/APPEND_SYSTEM.md"
echo "Ready-notify extension installed; set PI_READY_NOTIFY_* in the shell/service that launches Pi."
"$PI_BIN" --version
"$CODEX_BIN" --version
REMOTE
