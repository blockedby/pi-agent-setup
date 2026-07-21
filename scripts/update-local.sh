#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/runtime-paths.sh
source "$repo_root/scripts/lib/runtime-paths.sh"
# shellcheck source=lib/local-assets.sh
source "$repo_root/scripts/lib/local-assets.sh"

LOCAL_USER_HOME="${LOCAL_USER_HOME:-$HOME}"
AGENT_DIR="${PI_AGENT_DIR:-$LOCAL_USER_HOME/.pi/agent}"
PI_SETTINGS_FILE="${PI_SETTINGS_FILE:-settings/pi-settings.example.json}"
PI_VERSION="${PI_VERSION:-latest}"
CODEX_SUBMODULE="$repo_root/packages/pi-codex"
BROWSER_SKILL="$repo_root/skills/browser-chrome"
SETTINGS_PATH="$AGENT_DIR/settings.json"

case "$PI_SETTINGS_FILE" in
  /*) SETTINGS_SOURCE="$PI_SETTINGS_FILE" ;;
  *) SETTINGS_SOURCE="$repo_root/$PI_SETTINGS_FILE" ;;
esac

if [ ! -f "$SETTINGS_SOURCE" ]; then
  echo "PI_SETTINGS_FILE not found: $PI_SETTINGS_FILE" >&2
  echo "Use settings/pi-settings.example.json or an ignored settings/*.local.json copy." >&2
  exit 2
fi

command -v rsync >/dev/null || { echo "rsync is required" >&2; exit 1; }
command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 1; }

if [ ! -f "$CODEX_SUBMODULE/package.json" ]; then
  git -C "$repo_root" submodule update --init packages/pi-codex
fi
if [ ! -f "$BROWSER_SKILL/SKILL.md" ]; then
  git -C "$repo_root" submodule update --init --recursive skills/browser-chrome
fi

pi_setup_validate_assets "$repo_root"
python3 "$repo_root/scripts/lib/config-json.py" verify-package "$repo_root/package.json"
python3 "$repo_root/scripts/lib/config-json.py" verify-subagents "$repo_root/settings/pi-subagents.config.json"

NPM_BIN="$(resolve_pi_setup_npm "$LOCAL_USER_HOME")"
if [ -z "$NPM_BIN" ]; then
  echo "npm not found; cannot install Pi or pi-codex dependencies" >&2
  exit 1
fi

PI_BIN="$LOCAL_USER_HOME/.local/bin/pi"
if [ ! -x "$PI_BIN" ]; then
  echo "Installing Pi under $LOCAL_USER_HOME/.local"
  mkdir -p "$LOCAL_USER_HOME/.local"
  "$NPM_BIN" install -g --prefix "$LOCAL_USER_HOME/.local" \
    "@earendil-works/pi-coding-agent@$PI_VERSION"
fi
[ -x "$PI_BIN" ] || { echo "Pi executable was not installed at $PI_BIN" >&2; exit 1; }

configure_pi_bash_path "$LOCAL_USER_HOME"
export PATH="$LOCAL_USER_HOME/.local/bin:$LOCAL_USER_HOME/.vite-plus/bin:$PATH"

echo "Installing pi-codex runtime dependencies"
(cd "$CODEX_SUBMODULE" && "$NPM_BIN" ci --omit=dev)

pi_setup_install_assets "$repo_root" "$AGENT_DIR"

if [ ! -f "$SETTINGS_PATH" ]; then
  printf '{\n  "packages": []\n}\n' > "$SETTINGS_PATH"
fi
python3 "$repo_root/scripts/lib/config-json.py" update-settings \
  "$SETTINGS_PATH" "$CODEX_SUBMODULE" "$SETTINGS_SOURCE"

INSTALLED_BROWSER_SKILL="$AGENT_DIR/skills/browser-chrome"
python3 "$repo_root/scripts/lib/config-json.py" browser-chrome-mcp \
  "$AGENT_DIR/mcp.json" \
  "$INSTALLED_BROWSER_SKILL/scripts/mcp.sh" \
  "$INSTALLED_BROWSER_SKILL/scripts/control-mcp.sh"

pi_setup_secure_assets "$AGENT_DIR" "$LOCAL_USER_HOME"

agent_count="$(find "$repo_root/agents" -maxdepth 1 -type f -name '*.md' | wc -l)"
skill_count="$(find "$repo_root/skills" -mindepth 1 -maxdepth 1 -type d -exec test -f '{}/SKILL.md' ';' -print | wc -l)"
echo "Installed $agent_count agents and $skill_count skills."
echo "Pi: $PI_BIN"
echo "Restart Pi or use /reload to load the updated configuration."
