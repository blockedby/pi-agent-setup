#!/usr/bin/env bash
set -euo pipefail

LOCAL_USER_HOME="${LOCAL_USER_HOME:-$HOME}"
AGENT_DIR="${PI_AGENT_DIR:-$LOCAL_USER_HOME/.pi/agent}"
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CODEX_SUBMODULE="$repo_root/packages/pi-codex"
SETTINGS_PATH="$AGENT_DIR/settings.json"

if [ ! -f "$CODEX_SUBMODULE/package.json" ]; then
  echo "pi-codex submodule is not initialized; running git submodule update --init packages/pi-codex" >&2
  git -C "$repo_root" submodule update --init packages/pi-codex
fi

if [ ! -d "$CODEX_SUBMODULE/node_modules/@mozilla/readability" ]; then
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
  (
    cd "$CODEX_SUBMODULE"
    "$NPM_BIN" ci --omit=dev || "$NPM_BIN" install --omit=dev --package-lock=false
  )
fi

mkdir -p "$AGENT_DIR/agents" "$AGENT_DIR/skills"
install -m 0600 "$repo_root/agents/"*.md "$AGENT_DIR/agents/"
rsync -a "$repo_root/skills/" "$AGENT_DIR/skills/"
find "$AGENT_DIR/skills" -type d -exec chmod 700 {} +
find "$AGENT_DIR/skills" -type f -exec chmod 600 {} +

# Remove known renamed/disabled agents and chains so old executable files do not
# survive across local setup updates.
for stale in \
  tdd-coder.md \
  implementer.md \
  failure-classifier.md \
  aad-test-auditor.md \
  aad-reviewer.md \
  quinn-validator.md \
  aad-parallel-investigation.chain.md; do
  rm -f "$AGENT_DIR/agents/$stale" "$LOCAL_USER_HOME/.agents/$stale"
done

mkdir -p "$AGENT_DIR"
if [ ! -f "$SETTINGS_PATH" ]; then
  printf '{\n  "packages": []\n}\n' > "$SETTINGS_PATH"
  chmod 600 "$SETTINGS_PATH"
fi

python3 - "$SETTINGS_PATH" "$CODEX_SUBMODULE" <<'PY'
import json
import os
import sys
from datetime import datetime, timezone
from pathlib import Path

settings_path = Path(sys.argv[1]).expanduser().resolve()
codex_path = Path(sys.argv[2]).resolve()
settings_dir = settings_path.parent
relative_codex = os.path.relpath(codex_path, settings_dir)

with settings_path.open() as f:
    data = json.load(f)

backup_path = settings_path.with_name(
    settings_path.name + ".bak.update-local-" + datetime.now(timezone.utc).strftime("%Y%m%dT%H%M%SZ")
)
backup_path.write_text(settings_path.read_text())

packages = data.setdefault("packages", [])

def is_pi_codex_source(value: object) -> bool:
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
for item in packages:
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

echo "Installed local agents to $AGENT_DIR/agents"
echo "Verified codex_task is absent from installed local agents."
echo "Reload or restart Pi to pick up the updated agents/packages."
