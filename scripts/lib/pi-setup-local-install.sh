#!/usr/bin/env bash
set -euo pipefail

LOCAL_USER_HOME="${LOCAL_USER_HOME:-$HOME}"
AGENT_DIR="${PI_AGENT_DIR:-$LOCAL_USER_HOME/.pi/agent}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
# shellcheck source=lib/runtime-paths.sh
source "$repo_root/scripts/lib/runtime-paths.sh"
source "$repo_root/scripts/lib/setup-deployment.sh"
CODEX_SUBMODULE="$repo_root/packages/pi-codex"
SETTINGS_PATH="$AGENT_DIR/settings.json"
PI_SETTINGS_FILE="${PI_SETTINGS_FILE:-settings/pi-settings.example.json}"
SETTINGS_SOURCE="$repo_root/$PI_SETTINGS_FILE"
PI_VERSION="${PI_VERSION:-latest}"

if [ ! -f "$SETTINGS_SOURCE" ]; then
  echo "PI_SETTINGS_FILE not found: $PI_SETTINGS_FILE" >&2
  echo "Use settings/pi-settings.example.json or an ignored settings/*.local.json copy." >&2
  exit 2
fi

if [ ! -f "$CODEX_SUBMODULE/package.json" ]; then
  echo "pi-codex submodule is not initialized; running git submodule update --init packages/pi-codex" >&2
  git -C "$repo_root" submodule update --init packages/pi-codex
fi

NPM_BIN="$(resolve_pi_setup_npm "$LOCAL_USER_HOME")"
if [ -z "$NPM_BIN" ]; then
  echo "npm not found; cannot install packages/pi-codex runtime dependencies" >&2
  exit 1
fi

# Vite+ remains the preferred Node/npm provider, but Pi itself must not run from
# Vite+'s hashed package directories: their `#<id>` path segment is interpreted
# as a URL fragment by Jiti while loading extensions. Ensure the local target
# exists regardless of another Pi executable already present on PATH.
ACTIVE_PI_BIN="$LOCAL_USER_HOME/.local/bin/pi"
if [ ! -x "$ACTIVE_PI_BIN" ]; then
  echo "Installing Pi outside Vite+ under $LOCAL_USER_HOME/.local"
  mkdir -p "$LOCAL_USER_HOME/.local"
  "$NPM_BIN" install -g --prefix "$LOCAL_USER_HOME/.local" \
    "@earendil-works/pi-coding-agent@$PI_VERSION"
fi
if [ ! -x "$ACTIVE_PI_BIN" ]; then
  echo "Local Pi executable is not executable after install: $ACTIVE_PI_BIN" >&2
  exit 1
fi

configure_pi_bash_path "$LOCAL_USER_HOME"
export PATH="$LOCAL_USER_HOME/.local/bin:$LOCAL_USER_HOME/.vite-plus/bin:$PATH"
echo "Configured Bash PATH startup for Pi under $LOCAL_USER_HOME/.local/bin"
echo "Using Pi executable: $ACTIVE_PI_BIN"

# packages/pi-codex is our vendored local Pi package. Reinstall dependencies on
# every local setup update so the local path package is deterministic and cannot
# keep stale node_modules after the submodule pointer changes.
echo "Installing packages/pi-codex runtime dependencies with $NPM_BIN"
(cd "$CODEX_SUBMODULE" && "$NPM_BIN" ci --omit=dev)

python3 "$repo_root/scripts/lib/config-json.py" verify-package-extensions "$repo_root/package.json"

SUBAGENT_CONFIG_SOURCE="$repo_root/settings/pi-subagents.config.json"
if [ -f "$SUBAGENT_CONFIG_SOURCE" ]; then
  pi_setup_deploy_static_assets "$repo_root" "$AGENT_DIR" "$LOCAL_USER_HOME" "$SUBAGENT_CONFIG_SOURCE" merge
  printf '%s\n' 'Installed pi-subagents config.'
else
  echo "Missing pi-subagents config: $SUBAGENT_CONFIG_SOURCE" >&2
  exit 1
fi

MAGIC_MCP_CONFIG="$repo_root/skills/21st-magic-mcp/mcp/21st-magic.mcp.json"
if [ -f "$MAGIC_MCP_CONFIG" ]; then
  mkdir -p "$LOCAL_USER_HOME/.cache/21st-magic-mcp/test-results"
  python3 "$repo_root/scripts/lib/config-json.py" merge-mcp "$AGENT_DIR/mcp.json" "$MAGIC_MCP_CONFIG" update-local
fi

mkdir -p "$AGENT_DIR"
if [ ! -f "$SETTINGS_PATH" ]; then
  printf '{\n  "packages": []\n}\n' > "$SETTINGS_PATH"
fi
python3 "$repo_root/scripts/lib/config-json.py" update-settings "$SETTINGS_PATH" "$CODEX_SUBMODULE" "$SETTINGS_SOURCE"
pi_setup_secure_agent_assets "$AGENT_DIR" "$LOCAL_USER_HOME"

if grep -R --line-number --fixed-strings "codex_task" "$AGENT_DIR/agents" >/tmp/pi-agent-setup-codex-task-check.$$ 2>/dev/null; then
  echo "ERROR: codex_task is still present in installed local agents:" >&2
  cat /tmp/pi-agent-setup-codex-task-check.$$ >&2
  rm -f /tmp/pi-agent-setup-codex-task-check.$$
  exit 1
fi
rm -f /tmp/pi-agent-setup-codex-task-check.$$

echo "Installed local APPEND_SYSTEM.md to $AGENT_DIR/APPEND_SYSTEM.md"
echo "Installed local agents to $AGENT_DIR/agents"
echo "Verified codex_task is absent from installed local agents."
echo "Ready-notify config is read from PI_READY_NOTIFY_* in the shell that launches Pi."
echo "Reload or restart Pi to pick up the updated agents/packages."
