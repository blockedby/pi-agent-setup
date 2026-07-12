#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$repo_root"

required_agents=(
  aad-root-owner.md
  aad-slice-owner.md
  aad-implementer.md
  aad-explorer.md
  aad-failure-classifier.md
  aad-acceptance-auditor.md
  chrome-browser-agent.md
  visual-critic.md
)

for file in "${required_agents[@]}"; do
  test -f "agents/$file"
done

if find agents -maxdepth 1 -type f -name '*.chain.md' -print -quit | grep -q .; then
  echo "Legacy chain files must not be checked in:" >&2
  find agents -maxdepth 1 -type f -name '*.chain.md' -print >&2
  exit 1
fi

grep -Fxq '.pi/aad/' .gitignore

if grep -R --line-number --fixed-strings "codex_task" agents/*.md; then
  echo "Active AAD agents must not expose codex_task" >&2
  exit 1
fi

if grep -R --line-number -E 'thinking:[[:space:]]*(xhigh|max)|gpt-5\.6-[^[:space:]]+:(xhigh|max)' \
  agents settings/aad-routing.json APPEND_SYSTEM.md; then
  echo "xhigh/max are forbidden by the checked-in AAD policy" >&2
  exit 1
fi

python3 skills/aad-slicing-and-delegation/scripts/route-task.py \
  --config settings/aad-routing.json --self-test

python3 - <<'PY'
import json
from pathlib import Path

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
    text = (Path("agents") / filename).read_text()
    if f"model: {model}" not in text:
        raise SystemExit(f"{filename}: expected model {model}")
    if f"thinking: {thinking}" not in text:
        raise SystemExit(f"{filename}: expected thinking {thinking}")

slice_text = Path("agents/aad-slice-owner.md").read_text().lower()
for phrase in ("working owner", "implement ordinary", "separate `chrome-browser-agent`", "separate terra-high auditor"):
    if phrase not in slice_text:
        raise SystemExit(f"aad-slice-owner.md missing policy phrase: {phrase}")

config = json.loads(Path("settings/aad-routing.json").read_text())
for name, profile in config["profiles"].items():
    if profile["thinking"] in {"xhigh", "max"}:
        raise SystemExit(f"profile {name} uses forbidden thinking")
if config["defaults"].get("browserSeparateContext") is not True:
    raise SystemExit("browserSeparateContext must be true")
if set(config["defaults"].get("auditRoutes", [])) != {"slice", "root"}:
    raise SystemExit("auditRoutes must be slice and root")

for skill in Path("skills").glob("*/SKILL.md"):
    head = skill.read_text().splitlines()[:8]
    joined = "\n".join(head)
    if not joined.startswith("---\n") or "\nname:" not in joined or "\ndescription:" not in joined:
        raise SystemExit(f"invalid skill frontmatter: {skill}")

print("AAD static policy checks passed")
PY

grep -q "DIRECT" APPEND_SYSTEM.md
grep -q "SLICE" APPEND_SYSTEM.md
grep -q "ROOT" APPEND_SYSTEM.md
grep -q "CONSULT" APPEND_SYSTEM.md
grep -q "APPROVE" APPEND_SYSTEM.md
grep -qi "browser work always runs in a separate child context" APPEND_SYSTEM.md
grep -qi "independent auditor context" APPEND_SYSTEM.md

echo "AAD routing verification passed."
