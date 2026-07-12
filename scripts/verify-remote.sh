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
  test -d "$REQUESTED_REMOTE_USER_HOME" || {
    echo "REMOTE_USER_HOME does not exist: $REQUESTED_REMOTE_USER_HOME" >&2
    exit 2
  }
  REMOTE_USER_HOME="$REQUESTED_REMOTE_USER_HOME"
elif [ -n "${HOME:-}" ] && [ -d "$HOME" ]; then
  REMOTE_USER_HOME="$HOME"
else
  REMOTE_USER_HOME="/root"
fi

VP_BIN_DIR="$REMOTE_USER_HOME/.vite-plus/bin"
AGENT_DIR="$REMOTE_USER_HOME/.pi/agent"
export PATH="$VP_BIN_DIR:$PATH"

echo "== runtime =="
"$VP_BIN_DIR/node" --version
"$VP_BIN_DIR/npm" --version
"$VP_BIN_DIR/pi" --version
"$VP_BIN_DIR/codex" --version

for required in settings.json APPEND_SYSTEM.md aad-routing.json extensions/subagent/config.json; do
  test -f "$AGENT_DIR/$required"
done
test -d "$AGENT_DIR/agents"
test -d "$AGENT_DIR/skills"

grep -q "DIRECT" "$AGENT_DIR/APPEND_SYSTEM.md"
grep -q "aad-root-owner" "$AGENT_DIR/APPEND_SYSTEM.md"
grep -q "aad-slice-owner" "$AGENT_DIR/APPEND_SYSTEM.md"

required_agents=(
  aad-explorer.md
  aad-root-owner.md
  aad-slice-owner.md
  aad-acceptance-auditor.md
  aad-implementer.md
  aad-failure-classifier.md
  chrome-browser-agent.md
  visual-critic.md
)
for required in "${required_agents[@]}"; do
  test -f "$AGENT_DIR/agents/$required"
done

if find "$AGENT_DIR/agents" -maxdepth 1 -type f -name '*.chain.md' -print -quit | grep -q .; then
  echo "Static chain remains installed:" >&2
  find "$AGENT_DIR/agents" -maxdepth 1 -type f -name '*.chain.md' -print >&2
  exit 1
fi

if grep -R --line-number --fixed-strings "codex_task" "$AGENT_DIR/agents"; then
  echo "codex_task is exposed to an active AAD agent" >&2
  exit 1
fi

required_skills=(
  aad-codex-evidence
  aad-design-refinement
  aad-failure-classification
  aad-implementation-report
  aad-integration
  aad-plan-writing
  aad-reporting
  aad-review-handling
  aad-slicing-and-delegation
  aad-systematic-debugging
  aad-target-branch-preparation
  aad-task-package
  aad-verification
  aad-worktree-management
  acceptance-evidence-gate
  backend-api-data-quality
  browser-chrome
  browser-visual-report
  devops-runtime-readiness
  frontend-ui-quality
  visual-composition-quality
  21st-magic-mcp
)
for required in "${required_skills[@]}"; do
  test -f "$AGENT_DIR/skills/$required/SKILL.md"
done

python3 "$AGENT_DIR/skills/aad-slicing-and-delegation/scripts/route-task.py" \
  --config "$AGENT_DIR/aad-routing.json" --self-test

python3 - "$AGENT_DIR" <<'PY'
import json
import sys
from pathlib import Path

agent_dir = Path(sys.argv[1])
expected = {
    "aad-root-owner.md": ("openai-codex/gpt-5.6-sol", "high"),
    "aad-slice-owner.md": ("openai-codex/gpt-5.6-terra", "high"),
    "aad-implementer.md": ("openai-codex/gpt-5.6-sol", "high"),
    "aad-explorer.md": ("openai-codex/gpt-5.6-luna", "medium"),
    "aad-failure-classifier.md": ("openai-codex/gpt-5.6-luna", "medium"),
    "aad-acceptance-auditor.md": ("openai-codex/gpt-5.6-terra", "high"),
    "chrome-browser-agent.md": ("openai-codex/gpt-5.6-terra", "high"),
    "visual-critic.md": ("openai-codex/gpt-5.6-terra", "high"),
}
for filename, (model, thinking) in expected.items():
    text = (agent_dir / "agents" / filename).read_text()
    if f"model: {model}" not in text or f"thinking: {thinking}" not in text:
        raise SystemExit(f"unexpected model policy in {filename}")

routing = json.loads((agent_dir / "aad-routing.json").read_text())
if set(routing["forbiddenThinkingLevels"]) != {"xhigh", "max"}:
    raise SystemExit("routing forbidden thinking levels are incorrect")

subagent = json.loads((agent_dir / "extensions/subagent/config.json").read_text())
control = subagent.get("control", {})
if control.get("needsAttentionAfterMs") != 180000:
    raise SystemExit("pi-subagents needsAttentionAfterMs is not 180000")
if control.get("notifyOn") != ["needs_attention"]:
    raise SystemExit("pi-subagents notifyOn is incorrect")

print("model, routing, and control policy verified")
PY

python3 - "$AGENT_DIR/mcp.json" <<'PY'
import json
import sys
from pathlib import Path
data = json.loads(Path(sys.argv[1]).read_text())
server = data.get("mcpServers", {}).get("21st-magic")
if not server:
    raise SystemExit("21st-magic MCP server is not installed")
if server.get("command") != "npx":
    raise SystemExit("21st-magic MCP command is incorrect")
if "@21st-dev/magic@latest" not in server.get("args", []):
    raise SystemExit("21st-magic MCP package is incorrect")
print("MCP entry verified")
PY

echo "== pi packages =="
"$VP_BIN_DIR/pi" list | sed -n '1,160p'

echo "== smoke =="
timeout "${PI_SMOKE_TIMEOUT_SECONDS:-900}" "$VP_BIN_DIR/pi" --no-session --mode text -p 'Say OK and exit.' | tail -n 40
REMOTE
