#!/usr/bin/env bash
set -euo pipefail

LOCAL_USER_HOME="${LOCAL_USER_HOME:-$HOME}"
AGENT_DIR="${PI_AGENT_DIR:-$LOCAL_USER_HOME/.pi/agent}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CODEX_SUBMODULE="$repo_root/packages/pi-codex"
SETTINGS_PATH="$AGENT_DIR/settings.json"
PI_SETTINGS_FILE="${PI_SETTINGS_FILE:-settings/pi-settings.example.json}"
SETTINGS_SOURCE="$repo_root/$PI_SETTINGS_FILE"
ROUTING_SOURCE="$repo_root/settings/aad-routing.json"

bash "$repo_root/scripts/verify-aad-routing.sh"

if [ ! -f "$SETTINGS_SOURCE" ]; then
  echo "PI_SETTINGS_FILE not found: $PI_SETTINGS_FILE" >&2
  exit 2
fi
if [ ! -f "$ROUTING_SOURCE" ]; then
  echo "AAD routing config not found: $ROUTING_SOURCE" >&2
  exit 2
fi

if [ ! -f "$CODEX_SUBMODULE/package.json" ]; then
  echo "pi-codex submodule is not initialized; running git submodule update --init packages/pi-codex" >&2
  git -C "$repo_root" submodule update --init packages/pi-codex
fi

NPM_BIN="${NPM_BIN:-}"
if [ -z "$NPM_BIN" ] && [ -x "$LOCAL_USER_HOME/.vite-plus/bin/npm" ]; then
  NPM_BIN="$LOCAL_USER_HOME/.vite-plus/bin/npm"
fi
if [ -z "$NPM_BIN" ]; then
  NPM_BIN="$(command -v npm || true)"
fi
if [ -z "$NPM_BIN" ]; then
  echo "npm not found; cannot install packages/pi-codex runtime dependencies" >&2
  exit 1
fi

echo "Installing packages/pi-codex runtime dependencies with $NPM_BIN"
(cd "$CODEX_SUBMODULE" && "$NPM_BIN" ci --omit=dev)

python3 - "$repo_root/package.json" <<'PY'
import json
import sys
from pathlib import Path
data = json.loads(Path(sys.argv[1]).read_text())
if "./extensions/ready-notify.ts" not in data.get("pi", {}).get("extensions", []):
    raise SystemExit("package.json does not declare ./extensions/ready-notify.ts")
print("Verified ready-notify extension declaration.")
PY

mkdir -p "$AGENT_DIR/agents" "$AGENT_DIR/skills" "$AGENT_DIR/extensions" "$AGENT_DIR/extensions/subagent"
install -m 0600 "$repo_root/APPEND_SYSTEM.md" "$AGENT_DIR/APPEND_SYSTEM.md"
install -m 0600 "$ROUTING_SOURCE" "$AGENT_DIR/aad-routing.json"
install -m 0600 "$repo_root/agents/"*.md "$AGENT_DIR/agents/"
install -m 0600 "$repo_root/extensions/"*.ts "$AGENT_DIR/extensions/"

# Preserve unrelated user skills. Remove only known obsolete AAD paths, then overlay
# the checked-in skill set.
for stale_skill in aad-routing-and-delegation aad-task-record aad-evidence-and-acceptance; do
  rm -rf "$AGENT_DIR/skills/$stale_skill"
done
rsync -a "$repo_root/skills/" "$AGENT_DIR/skills/"

SUBAGENT_CONFIG_SOURCE="$repo_root/settings/pi-subagents.config.json"
if [ -f "$SUBAGENT_CONFIG_SOURCE" ]; then
  install -m 0600 "$SUBAGENT_CONFIG_SOURCE" "$AGENT_DIR/extensions/subagent/config.json"
fi

MAGIC_MCP_CONFIG="$repo_root/skills/21st-magic-mcp/mcp/21st-magic.mcp.json"
if [ -f "$MAGIC_MCP_CONFIG" ]; then
  mkdir -p "$LOCAL_USER_HOME/.cache/21st-magic-mcp/test-results"
  python3 - "$AGENT_DIR/mcp.json" "$MAGIC_MCP_CONFIG" <<'PY'
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
mcp_path = Path(sys.argv[1])
config_path = Path(sys.argv[2])
data = json.loads(mcp_path.read_text()) if mcp_path.exists() else {}
config = json.loads(config_path.read_text())
data.setdefault("mcpServers", {}).update(config.get("mcpServers", {}))
mcp_path.parent.mkdir(parents=True, exist_ok=True)
if mcp_path.exists():
    backup = mcp_path.with_name(
        mcp_path.name + ".bak.update-local-" + datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
    )
    backup.write_text(mcp_path.read_text())
mcp_path.write_text(json.dumps(data, indent=2) + "\n")
PY
  chmod 600 "$AGENT_DIR/mcp.json"
fi

# Remove renamed/disabled agents and every retired static chain.
for stale in \
  tdd-coder.md \
  implementer.md \
  failure-classifier.md \
  aad-test-auditor.md \
  aad-reviewer.md \
  quinn-validator.md \
  aad-parallel-investigation.chain.md \
  aad-discovery-plan.chain.md \
  aad-owned-change.chain.md \
  aad-problem-investigation.chain.md \
  visual-ui-change.chain.md; do
  rm -f "$AGENT_DIR/agents/$stale" "$LOCAL_USER_HOME/.agents/$stale"
done

find "$AGENT_DIR/skills" -type d -exec chmod 700 {} +
find "$AGENT_DIR/skills" -type f -exec chmod 600 {} +
find "$AGENT_DIR/skills" -type f -path '*/scripts/*.py' -exec chmod 700 {} +
find "$AGENT_DIR/extensions" -type f -exec chmod 600 {} +

if [ ! -f "$SETTINGS_PATH" ]; then
  printf '{\n  "packages": []\n}\n' > "$SETTINGS_PATH"
  chmod 600 "$SETTINGS_PATH"
fi

python3 - "$SETTINGS_PATH" "$CODEX_SUBMODULE" "$SETTINGS_SOURCE" <<'PY'
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

settings_path = Path(sys.argv[1]).expanduser().resolve()
codex_path = Path(sys.argv[2]).resolve()
settings_source = Path(sys.argv[3]).resolve()
relative_codex = os.path.relpath(codex_path, settings_path.parent)

data = json.loads(settings_path.read_text())
desired = json.loads(settings_source.read_text())
backup_path = settings_path.with_name(
    settings_path.name + ".bak.update-local-" + datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
)
backup_path.write_text(settings_path.read_text())

def is_pi_codex_source(value):
    if not isinstance(value, str):
        return False
    normalized = value.rstrip("/")
    return (
        normalized == "git:github.com/blockedby/pi-codex"
        or normalized == "https://github.com/blockedby/pi-codex"
        or normalized.endswith("/pi-codex")
        or normalized.endswith("/pi-codex.git")
    )

found = False
new_packages = []
for item in data.setdefault("packages", []):
    if is_pi_codex_source(item):
        if not found:
            new_packages.append(relative_codex)
            found = True
        continue
    if isinstance(item, dict) and is_pi_codex_source(item.get("source")):
        if not found:
            updated = dict(item)
            updated["source"] = relative_codex
            new_packages.append(updated)
            found = True
        continue
    new_packages.append(item)
if not found:
    new_packages.insert(0, relative_codex)

data["packages"] = new_packages
for key in ("defaultProvider", "defaultModel", "defaultThinkingLevel"):
    if key in desired:
        data[key] = desired[key]
settings_path.write_text(json.dumps(data, indent=2) + "\n")
print(f"settings backup: {backup_path}")
print(f"pi-codex package: {relative_codex}")
PY

if grep -R --line-number --fixed-strings "codex_task" "$AGENT_DIR/agents" >/tmp/pi-agent-setup-codex-task-check.$$ 2>/dev/null; then
  echo "ERROR: codex_task is still present in installed local agents:" >&2
  cat /tmp/pi-agent-setup-codex-task-check.$$ >&2
  rm -f /tmp/pi-agent-setup-codex-task-check.$$
  exit 1
fi
rm -f /tmp/pi-agent-setup-codex-task-check.$$

if find "$AGENT_DIR/agents" -maxdepth 1 -type f -name '*.chain.md' -print -quit | grep -q .; then
  echo "ERROR: legacy chain remains installed" >&2
  find "$AGENT_DIR/agents" -maxdepth 1 -type f -name '*.chain.md' -print >&2
  exit 1
fi

python3 "$AGENT_DIR/skills/aad-slicing-and-delegation/scripts/route-task.py" \
  --config "$AGENT_DIR/aad-routing.json" --self-test

echo "Installed local prompt, active agents, skills, routing config, and extensions under $AGENT_DIR"
echo "Preserved unrelated user skills and removed retired static chains."
echo "Reload or restart Pi to pick up the updated resources."
