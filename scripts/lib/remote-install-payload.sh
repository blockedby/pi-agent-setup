#!/usr/bin/env bash
set -euo pipefail

REQUESTED_REMOTE_USER_HOME="$1"
PI_VERSION="$2"
CODEX_VERSION="$3"
TMP_DIR="$4"
source "$TMP_DIR/scripts/lib/setup-common.sh"
source "$TMP_DIR/scripts/lib/runtime-paths.sh"
source "$TMP_DIR/scripts/lib/setup-deployment.sh"

REMOTE_USER_HOME="$(pi_setup_resolve_home "$REQUESTED_REMOTE_USER_HOME")"
VP_BIN="$REMOTE_USER_HOME/.vite-plus/bin/vp"
NPM_BIN="$REMOTE_USER_HOME/.vite-plus/bin/npm"
PI_BIN="$REMOTE_USER_HOME/.local/bin/pi"
CODEX_BIN="$REMOTE_USER_HOME/.vite-plus/bin/codex"
AGENT_DIR="$REMOTE_USER_HOME/.pi/agent"
export PATH="$REMOTE_USER_HOME/.local/bin:$REMOTE_USER_HOME/.vite-plus/bin:$PATH"

pi_setup_require_executable "$NPM_BIN" "Vite+ npm"
pi_setup_require_executable "$VP_BIN" "Vite+ vp"
mkdir -p "$REMOTE_USER_HOME/.local"
"$NPM_BIN" install -g --prefix "$REMOTE_USER_HOME/.local" "@earendil-works/pi-coding-agent@$PI_VERSION"
"$VP_BIN" install -g "@openai/codex@$CODEX_VERSION"
configure_pi_bash_path "$REMOTE_USER_HOME"

pi_setup_deploy_static_assets "$TMP_DIR" "$AGENT_DIR" "$REMOTE_USER_HOME" "$TMP_DIR/settings/pi-subagents.config.json" replace
pi_setup_replace_settings "$TMP_DIR/settings/settings.json" "$AGENT_DIR"
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
pi_setup_secure_agent_assets "$AGENT_DIR" "$REMOTE_USER_HOME"
printf 'Installed Pi agent setup under %s\n' "$AGENT_DIR"
printf 'Global append system prompt installed at %s/APPEND_SYSTEM.md\n' "$AGENT_DIR"
printf '%s\n' 'Ready-notify extension installed; set PI_READY_NOTIFY_* in the shell/service that launches Pi.'
"$PI_BIN" --version
"$CODEX_BIN" --version
