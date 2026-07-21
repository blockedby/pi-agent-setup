#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/local-assets.sh
source "$repo_root/scripts/lib/local-assets.sh"

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT
fail() { echo "local asset test failed: $*" >&2; exit 1; }

pi_setup_validate_assets "$repo_root"

agent_dir="$tmp_root/home/.pi/agent"
mkdir -p \
  "$agent_dir/agents" \
  "$agent_dir/skills/custom-skill" \
  "$agent_dir/skills/vercel-optimize" \
  "$agent_dir/skills/aad-target-branch-preparation" \
  "$agent_dir/skills/21st-magic-mcp" \
  "$agent_dir/skills/visual-composition-quality"
printf 'custom\n' > "$agent_dir/agents/custom-agent.md"
printf 'custom\n' > "$agent_dir/agents/visual-ui-change.chain.md"
printf 'stale\n' > "$agent_dir/agents/visual-critic.md"
printf 'custom\n' > "$agent_dir/skills/custom-skill/SKILL.md"
printf 'external\n' > "$agent_dir/skills/vercel-optimize/SKILL.md"
printf 'stale\n' > "$agent_dir/skills/aad-target-branch-preparation/SKILL.md"
printf 'stale\n' > "$agent_dir/skills/21st-magic-mcp/SKILL.md"
printf 'stale\n' > "$agent_dir/skills/visual-composition-quality/SKILL.md"
printf 'stale\n' > "$agent_dir/agents/aad-old-owner.md"

pi_setup_install_assets "$repo_root" "$agent_dir"
pi_setup_secure_assets "$agent_dir" "$tmp_root/home"

test -f "$agent_dir/agents/custom-agent.md" || fail "custom agent was removed"
test -f "$agent_dir/agents/visual-ui-change.chain.md" || fail "non-historical chain was removed"
test -f "$agent_dir/skills/custom-skill/SKILL.md" || fail "custom skill was removed"
test -f "$agent_dir/skills/vercel-optimize/SKILL.md" || fail "external skill was removed"
test ! -e "$agent_dir/agents/aad-old-owner.md" || fail "stale AAD agent survived"
test ! -e "$agent_dir/agents/visual-critic.md" || fail "historical visual critic survived"
test ! -e "$agent_dir/skills/aad-target-branch-preparation" || fail "renamed AAD skill survived"
test ! -e "$agent_dir/skills/21st-magic-mcp" || fail "historical 21st skill survived"
test ! -e "$agent_dir/skills/visual-composition-quality" || fail "historical visual skill survived"

for source in "$repo_root"/agents/*.md; do
  cmp -s "$source" "$agent_dir/agents/$(basename "$source")" || fail "agent differs: $source"
done
for skill in "$repo_root"/skills/*; do
  [ -f "$skill/SKILL.md" ] || continue
  target="$agent_dir/skills/$(basename "$skill")"
  while IFS= read -r -d '' source; do
    relative="${source#"$skill/"}"
    [ "$relative" = .git ] && continue
    cmp -s "$source" "$target/$relative" || fail "skill file differs: $source"
  done < <(find "$skill" -type f -print0)
done

test -x "$agent_dir/skills/aad-git-branching/scripts/prepare-target-branch.sh" || fail "nested skill script is not executable"

# A second install must replace stale files inside repository-owned skills.
printf 'stale\n' > "$agent_dir/skills/aad-git-branching/stale.txt"
pi_setup_install_assets "$repo_root" "$agent_dir"
test ! -e "$agent_dir/skills/aad-git-branching/stale.txt" || fail "stale skill file survived"

if rg -n 'python3?[[:space:]]+-([[:space:]]|$)|<<.*PY' \
  "$repo_root/scripts/update-local.sh" "$repo_root/scripts/lib" -g '*.sh'; then
  fail "embedded Python found in shell"
fi

printf 'local asset tests passed\n'
