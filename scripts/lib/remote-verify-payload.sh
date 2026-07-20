#!/usr/bin/env bash
set -euo pipefail

REQUESTED_REMOTE_USER_HOME="$1"
TMP_DIR="$2"
source "$TMP_DIR/scripts/lib/setup-common.sh"
source "$TMP_DIR/scripts/lib/setup-verification.sh"
REMOTE_USER_HOME="$(pi_setup_resolve_home "$REQUESTED_REMOTE_USER_HOME")"
VP_BIN_DIR="$REMOTE_USER_HOME/.vite-plus/bin"
LOCAL_BIN_DIR="$REMOTE_USER_HOME/.local/bin"
PI_BIN="$LOCAL_BIN_DIR/pi"
AGENT_DIR="$REMOTE_USER_HOME/.pi/agent"
export PATH="$LOCAL_BIN_DIR:$VP_BIN_DIR:$PATH"

printf '%s\n%s\n' '== resolved home ==' "$REMOTE_USER_HOME"
printf '%s\n' '== vite node/npm/codex and npm-installed pi =='
"$VP_BIN_DIR/node" --version
"$VP_BIN_DIR/npm" --version
test "$(command -v pi)" = "$PI_BIN"
"$PI_BIN" --version
"$VP_BIN_DIR/codex" --version
login_pi="$(HOME="$REMOTE_USER_HOME" PATH="$VP_BIN_DIR:/usr/bin:/bin" bash --login -i -c 'command -v pi' 2>/dev/null | tail -n 1)"
interactive_pi="$(HOME="$REMOTE_USER_HOME" PATH="$VP_BIN_DIR:/usr/bin:/bin" bash -i -c 'command -v pi' 2>/dev/null | tail -n 1)"
test "$login_pi" = "$PI_BIN"
test "$interactive_pi" = "$PI_BIN"
printf '%s\n' 'Fresh Bash login and interactive shells resolve Pi from .local/bin.'

printf '%s\n' '== pi files =='
test -f "$AGENT_DIR/settings.json"
test -f "$AGENT_DIR/APPEND_SYSTEM.md"
grep -q 'aad-root-owner' "$AGENT_DIR/APPEND_SYSTEM.md"
grep -q 'aad-slice-owner' "$AGENT_DIR/APPEND_SYSTEM.md"
test -d "$AGENT_DIR/agents"
test -d "$AGENT_DIR/skills"
test -f "$AGENT_DIR/extensions/subagent/config.json"
find "$AGENT_DIR/agents" -maxdepth 1 -type f -name '*.md' -printf '%f\n' | sort
find "$AGENT_DIR/skills" -maxdepth 2 -type f -path '*/SKILL.md' -printf '%h\n' | sed "s#^$AGENT_DIR/skills/##" | sort
pi_setup_verify_agents "$AGENT_DIR" "$REMOTE_USER_HOME"
python3 "$TMP_DIR/scripts/lib/config-json.py" verify-subagents "$AGENT_DIR/extensions/subagent/config.json"
printf '%s\n' '== pi packages =='
"$PI_BIN" list | sed -n '1,160p'
printf '%s\n' '== smoke =='
timeout "${PI_SMOKE_TIMEOUT_SECONDS:-900}" "$PI_BIN" --no-session --mode text -p 'Say OK and exit.' | tail -n 40
