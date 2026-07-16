#!/usr/bin/env bash
set -euo pipefail

TARGET_HOST="${TARGET_HOST:-}"
REMOTE_USER_HOME="${REMOTE_USER_HOME:-}"
if [ -z "$TARGET_HOST" ]; then
  echo "TARGET_HOST is required, for example: TARGET_HOST=<host> $0" >&2
  exit 2
fi

ssh "$TARGET_HOST" bash -s -- "$REMOTE_USER_HOME" <<'REMOTE'
set -euo pipefail
REQUESTED_REMOTE_USER_HOME="$1"

if [ -n "$REQUESTED_REMOTE_USER_HOME" ]; then
  if [ -d "$REQUESTED_REMOTE_USER_HOME" ]; then
    REMOTE_USER_HOME="$REQUESTED_REMOTE_USER_HOME"
  else
    echo "REMOTE_USER_HOME does not exist on target: $REQUESTED_REMOTE_USER_HOME" >&2
    exit 2
  fi
elif [ -n "${HOME:-}" ] && [ -d "$HOME" ]; then
  REMOTE_USER_HOME="$HOME"
else
  REMOTE_USER_HOME="/root"
fi

VP_BIN_DIR="$REMOTE_USER_HOME/.vite-plus/bin"
LOCAL_BIN_DIR="$REMOTE_USER_HOME/.local/bin"
PI_BIN="$LOCAL_BIN_DIR/pi"
AGENT_DIR="$REMOTE_USER_HOME/.pi/agent"
export PATH="$LOCAL_BIN_DIR:$VP_BIN_DIR:$PATH"

echo "== resolved home =="
echo "$REMOTE_USER_HOME"

echo '== vite node/npm/codex and npm-installed pi =='
"$VP_BIN_DIR/node" --version
"$VP_BIN_DIR/npm" --version
test "$(command -v pi)" = "$PI_BIN"
"$PI_BIN" --version
"$VP_BIN_DIR/codex" --version

login_pi="$(HOME="$REMOTE_USER_HOME" PATH="$VP_BIN_DIR:/usr/bin:/bin" bash --login -i -c 'command -v pi' 2>/dev/null | tail -n 1)"
interactive_pi="$(HOME="$REMOTE_USER_HOME" PATH="$VP_BIN_DIR:/usr/bin:/bin" bash -i -c 'command -v pi' 2>/dev/null | tail -n 1)"
test "$login_pi" = "$PI_BIN"
test "$interactive_pi" = "$PI_BIN"
echo 'Fresh Bash login and interactive shells resolve Pi from .local/bin.'

echo '== pi files =='
test -f "$AGENT_DIR/settings.json"
test -f "$AGENT_DIR/APPEND_SYSTEM.md"
grep -q "aad-root-owner" "$AGENT_DIR/APPEND_SYSTEM.md"
grep -q "aad-slice-owner" "$AGENT_DIR/APPEND_SYSTEM.md"
test -d "$AGENT_DIR/agents"
test -d "$AGENT_DIR/skills"
test -f "$AGENT_DIR/extensions/subagent/config.json"
find "$AGENT_DIR/agents" -maxdepth 1 -type f -name '*.md' -printf '%f\n' | sort
find "$AGENT_DIR/skills" -maxdepth 2 -type f -path '*/SKILL.md' -printf '%h\n' | sed "s#^$AGENT_DIR/skills/##" | sort

for required in \
  aad-explorer.md \
  aad-root-owner.md \
  aad-slice-owner.md \
  aad-acceptance-auditor.md \
  aad-implementer.md \
  aad-failure-classifier.md \
  chrome-browser-agent.md \
  aad-discovery-plan.chain.md \
  aad-owned-change.chain.md \
  aad-problem-investigation.chain.md; do
  test -f "$AGENT_DIR/agents/$required"
done

for stale in \
  tdd-coder.md \
  implementer.md \
  failure-classifier.md \
  aad-test-auditor.md \
  aad-reviewer.md \
  quinn-validator.md \
  aad-parallel-investigation.chain.md; do
  for stale_dir in "$AGENT_DIR/agents" "$REMOTE_USER_HOME/.agents"; do
    if [ -e "$stale_dir/$stale" ]; then
      echo "stale executable agent/chain still installed: $stale_dir/$stale" >&2
      exit 1
    fi
  done
done

for required in \
  aad-design-refinement \
  aad-failure-classification \
  aad-implementation-report \
  aad-integration \
  aad-plan-writing \
  aad-reporting \
  aad-review-handling \
  aad-slicing-and-delegation \
  aad-systematic-debugging \
  aad-target-branch-preparation \
  aad-task-package \
  aad-verification \
  aad-worktree-management \
  browser-chrome \
  21st-magic-mcp; do
  test -f "$AGENT_DIR/skills/$required/SKILL.md"
done

python3 - "$AGENT_DIR/extensions/subagent/config.json" <<'PY'
import json
import sys
from pathlib import Path

config_path = Path(sys.argv[1])
data = json.loads(config_path.read_text())
scheduled_runs = data.get("scheduledRuns", {})
if scheduled_runs.get("enabled") is not True:
    raise SystemExit("pi-subagents scheduledRuns.enabled is not true")
control = data.get("control", {})
if control.get("needsAttentionAfterMs") != 180000:
    raise SystemExit("pi-subagents needsAttentionAfterMs is not 180000")
if control.get("notifyOn") != ["needs_attention"]:
    raise SystemExit("pi-subagents notifyOn must be ['needs_attention']")
print("pi-subagents scheduled-runs and control config verified")
PY

python3 - "$AGENT_DIR/mcp.json" <<'PY'
import json
import sys
from pathlib import Path

mcp_path = Path(sys.argv[1])
data = json.loads(mcp_path.read_text())
server = data.get("mcpServers", {}).get("21st-magic")
if not server:
    raise SystemExit("21st-magic MCP server is not installed")
if server.get("command") != "npx":
    raise SystemExit("21st-magic MCP server does not use npx")
if "@21st-dev/magic@latest" not in server.get("args", []):
    raise SystemExit("21st-magic MCP server does not reference @21st-dev/magic@latest")
for name in ("TWENTY_FIRST_API_KEY", "API_KEY"):
    value = server.get("env", {}).get(name, "")
    if value and value != "${" + name + "}":
        raise SystemExit(f"21st-magic MCP {name} must remain an env reference")
print("21st-magic MCP entry verified")
PY

echo '== pi packages =='
"$PI_BIN" list | sed -n '1,160p'

echo '== smoke =='
timeout "${PI_SMOKE_TIMEOUT_SECONDS:-900}" "$PI_BIN" --no-session --mode text -p 'Say OK and exit.' | tail -n 40
REMOTE
