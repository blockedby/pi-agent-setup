#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/local-assets.sh
source "$repo_root/scripts/lib/local-assets.sh"

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT
fail() { echo "local asset test failed: $*" >&2; exit 1; }

write_skill() {
  local root="$1" set_name="$2" relative="$3" name="$4"
  local directory="$root/skills/$set_name/$relative"
  mkdir -p "$directory"
  cat > "$directory/SKILL.md" <<EOF
---
name: $name
description: Test description for $name.
---

# $name
EOF
  printf 'support for %s\n' "$name" > "$directory/support.txt"
}

make_repo() {
  local root="$1" name
  mkdir -p "$root/scripts/lib" "$root/skills/aad" "$root/skills/general" \
    "$root/agents" "$root/extensions" "$root/settings"
  cp "$repo_root/scripts/lib/skill-assets.py" "$root/scripts/lib/skill-assets.py"
  cp "$repo_root/scripts/lib/local-assets.sh" "$root/scripts/lib/local-assets.sh"
  cp "$repo_root/scripts/install-skills.sh" "$root/scripts/install-skills.sh"
  chmod +x "$root/scripts/install-skills.sh" "$root/scripts/lib/skill-assets.py"
  printf 'system\n' > "$root/APPEND_SYSTEM.md"
  printf '{}\n' > "$root/settings/pi-subagents.config.json"
  cat > "$root/agents/aad-owner.md" <<'EOF'
---
name: aad-owner
description: Test owner.
---
EOF
  printf 'export default {}\n' > "$root/extensions/example.ts"

  for name in \
    aad-delegation \
    aad-plan-writing \
    aad-reporting \
    aad-task-package \
    aad-workflow-feedback; do
    write_skill "$root" aad "$name" "$name"
  done
  write_skill "$root" common git-branching git-branching
  for name in \
    backend-quality \
    completion-verification \
    devops-quality \
    explanatory-html-pages \
    frontend-quality \
    modern-skill-revising \
    visual-composition; do
    write_skill "$root" general "group/$name" "$name"
  done
  write_skill "$root" general browser-chrome browser-chrome

  mkdir -p "$root/skills/common/git-branching/scripts"
  printf '#!/usr/bin/env bash\necho prepared\n' > \
    "$root/skills/common/git-branching/scripts/prepare-target-branch.sh"
  printf '#!/usr/bin/env bash\necho synced\n' > \
    "$root/skills/common/git-branching/scripts/sync-target-branch.sh"
  chmod +x \
    "$root/skills/common/git-branching/scripts/prepare-target-branch.sh" \
    "$root/skills/common/git-branching/scripts/sync-target-branch.sh"
}

assert_manifest_set() {
  local manifest="$1" set_name="$2" expected="$3" cleanup="${4:-0}"
  python3 -c '
import json, sys
manifest, set_name, expected, cleanup = sys.argv[1], sys.argv[2], int(sys.argv[3]), int(sys.argv[4])
data = json.load(open(manifest, encoding="utf-8"))
assert data["schemaVersion"] == 1
assert len(data["skillSets"][set_name]) == expected
assert data["legacyCleanup"][set_name] == cleanup
' "$manifest" "$set_name" "$expected" "$cleanup" || fail "unexpected $set_name manifest"
}

expect_install_failure() {
  local source_root="$1" agent_dir="$2" set_name="$3" migration_mode="${4:-}"
  if pi_setup_install_skills \
    "$source_root" "$agent_dir" "$set_name" "$migration_mode" >/dev/null 2>&1; then
    fail "set=$set_name unexpectedly installed from $source_root"
  fi
}

fixture="$tmp_root/repo"
make_repo "$fixture"

[ "$(pi_setup_count_skills "$fixture" general)" -eq 8 ] || fail "general recursive count is not 8"
[ "$(pi_setup_count_skills "$fixture" common)" -eq 1 ] || fail "common recursive count is not 1"
[ "$(pi_setup_count_skills "$fixture" aad)" -eq 5 ] || fail "AAD recursive count is not 5"
[ "$(pi_setup_count_skills "$fixture" all)" -eq 14 ] || fail "combined recursive count is not 14"
pi_setup_validate_assets "$fixture" all
pi_setup_validate_assets "$repo_root" all
test -x "$repo_root/skills/common/git-branching/scripts/prepare-target-branch.sh" || \
  fail "checked-in prepare helper is not executable"
test -x "$repo_root/skills/common/git-branching/scripts/sync-target-branch.sh" || \
  fail "checked-in sync helper is not executable"

# The public entrypoint supports a safe explicit target override and performs
# no full-setup writes.
cli_agent="$tmp_root/cli-agent"
"$fixture/scripts/install-skills.sh" --set general --agent-dir "$cli_agent" >/dev/null
test -f "$cli_agent/skills/browser-chrome/SKILL.md" || fail "CLI general install missed Browser Chrome"
"$fixture/scripts/install-skills.sh" --set common --agent-dir "$cli_agent" >/dev/null
test -f "$cli_agent/skills/git-branching/SKILL.md" || fail "CLI common install missed Git branching"
test ! -e "$cli_agent/agents" || fail "CLI skill install created agents"
assert_manifest_set "$cli_agent/.pi-agent-setup-skills.json" common 1
assert_manifest_set "$cli_agent/.pi-agent-setup-skills.json" general 8

# General installation is skills-only and preserves unrelated/unselected and
# legacy destinations unless the full updater explicitly adopts its old assets.
general_agent="$tmp_root/general-agent"
mkdir -p \
  "$general_agent/skills/custom-skill" \
  "$general_agent/skills/aad-delegation" \
  "$general_agent/skills/aad-quality-backend" \
  "$general_agent/skills/backend-api-data-quality" \
  "$general_agent/skills/aad-target-branch-preparation"
printf 'custom\n' > "$general_agent/skills/custom-skill/SKILL.md"
printf 'existing aad\n' > "$general_agent/skills/aad-delegation/SKILL.md"
printf 'legacy\n' > "$general_agent/skills/aad-quality-backend/SKILL.md"
printf 'legacy\n' > "$general_agent/skills/backend-api-data-quality/SKILL.md"
printf 'unselected legacy\n' > "$general_agent/skills/aad-target-branch-preparation/SKILL.md"
cat > "$general_agent/.pi-agent-setup-skills.json" <<'EOF'
{
  "schemaVersion": 1,
  "skillSets": {"aad": ["aad-delegation"], "general": []},
  "legacyCleanup": {"aad": 0, "general": 0}
}
EOF

[ "$(pi_setup_install_skills "$fixture" "$general_agent" general)" -eq 8 ] || fail "general count changed"
test -f "$general_agent/skills/backend-quality/SKILL.md" || fail "general skill missing"
cmp -s "$fixture/skills/general/group/backend-quality/support.txt" \
  "$general_agent/skills/backend-quality/support.txt" || fail "general support file changed"
test -f "$general_agent/skills/browser-chrome/SKILL.md" || fail "browser skill missing"
test -f "$general_agent/skills/aad-quality-backend/SKILL.md" || fail "public install removed renamed legacy skill"
test -f "$general_agent/skills/backend-api-data-quality/SKILL.md" || fail "public install removed historical skill"
test -f "$general_agent/skills/aad-target-branch-preparation/SKILL.md" || fail "unselected legacy skill was removed"
test -f "$general_agent/skills/aad-delegation/SKILL.md" || fail "unselected owned skill was removed"
test -f "$general_agent/skills/custom-skill/SKILL.md" || fail "unrelated skill was removed"
test ! -e "$general_agent/agents" || fail "skill-only install created agents"
test ! -e "$general_agent/APPEND_SYSTEM.md" || fail "skill-only install copied the system prompt"
test ! -e "$general_agent/extensions" || fail "skill-only install created extensions"
test ! -e "$general_agent/settings.json" || fail "skill-only install created settings"
test ! -e "$general_agent/mcp.json" || fail "skill-only install created MCP configuration"
assert_manifest_set "$general_agent/.pi-agent-setup-skills.json" general 8
assert_manifest_set "$general_agent/.pi-agent-setup-skills.json" aad 1 0

# Reinstallation replaces complete owned destinations, including stale support
# files, while preserving source file modes.
printf 'stale\n' > "$general_agent/skills/backend-quality/stale.txt"
pi_setup_install_skills "$fixture" "$general_agent" general >/dev/null
test ! -e "$general_agent/skills/backend-quality/stale.txt" || fail "stale internal file survived"

# Legacy cleanup is restricted to the full updater's explicit adoption mode.
printf 'new external owner\n' > "$general_agent/skills/aad-quality-backend/SKILL.md"
pi_setup_install_skills "$fixture" "$general_agent" general >/dev/null
test -f "$general_agent/skills/aad-quality-backend/SKILL.md" || fail "public install deleted a legacy name"

# Exact selected-set pruning follows prior manifest ownership.
prune_repo="$tmp_root/prune-repo"
cp -a "$fixture" "$prune_repo"
rm -rf "$prune_repo/skills/general/group/backend-quality"
if pi_setup_validate_skills "$prune_repo" general >/dev/null 2>&1; then
  fail "checked-in profile validation accepted a missing expected skill"
fi
# The publication primitive remains version-agnostic so a later intentional
# inventory change can prune ownership once the canonical profile is updated.
pi_setup_install_skills "$prune_repo" "$general_agent" general >/dev/null
test ! -e "$general_agent/skills/backend-quality" || fail "removed owned general skill was not pruned"
test -f "$general_agent/skills/aad-delegation/SKILL.md" || fail "pruning touched unselected AAD skill"
assert_manifest_set "$general_agent/.pi-agent-setup-skills.json" general 7

# AAD-only neither initializes nor installs Browser Chrome. Installing AAD
# after general remains additive.
aad_agent="$tmp_root/aad-agent"
git_log="$tmp_root/git.log"
fake_git="$tmp_root/fake-git"
cat > "$fake_git" <<'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "$GIT_LOG"
EOF
chmod +x "$fake_git"
no_browser_repo="$tmp_root/no-browser-repo"
cp -a "$fixture" "$no_browser_repo"
rm -rf "$no_browser_repo/skills/general/browser-chrome"
GIT_BIN="$fake_git" GIT_LOG="$git_log" pi_setup_initialize_skill_sources "$no_browser_repo" aad
GIT_BIN="$fake_git" GIT_LOG="$git_log" pi_setup_initialize_skill_sources "$no_browser_repo" common
[ ! -e "$git_log" ] || fail "AAD/common-only initialized Browser Chrome"
GIT_BIN="$fake_git" GIT_LOG="$git_log" pi_setup_initialize_skill_sources "$no_browser_repo" general
grep -Fq 'skills/general/browser-chrome' "$git_log" || fail "general did not lazily initialize moved Browser Chrome"

pi_setup_install_skills "$fixture" "$aad_agent" aad >/dev/null
test -f "$aad_agent/skills/aad-delegation/SKILL.md" || fail "AAD skill missing"
test ! -e "$aad_agent/skills/browser-chrome" || fail "AAD-only installed Browser Chrome"
test ! -e "$aad_agent/skills/git-branching" || fail "AAD-only installed common Git branching"
assert_manifest_set "$aad_agent/.pi-agent-setup-skills.json" aad 5
pi_setup_install_skills "$fixture" "$aad_agent" common >/dev/null
pi_setup_install_skills "$fixture" "$aad_agent" general >/dev/null
pi_setup_install_skills "$fixture" "$aad_agent" aad >/dev/null
test -f "$aad_agent/skills/git-branching/SKILL.md" || fail "additive common install missing"
test -f "$aad_agent/skills/browser-chrome/SKILL.md" || fail "additive general install missing"
assert_manifest_set "$aad_agent/.pi-agent-setup-skills.json" common 1
assert_manifest_set "$aad_agent/.pi-agent-setup-skills.json" general 8

# Explicit unselected manifest ownership wins over a selected set's legacy
# migration allowlist.
legacy_owner_agent="$tmp_root/legacy-owner-agent"
mkdir -p "$legacy_owner_agent/skills/agent-pipeline-feedback"
printf 'unselected owner\n' > "$legacy_owner_agent/skills/agent-pipeline-feedback/SKILL.md"
cat > "$legacy_owner_agent/.pi-agent-setup-skills.json" <<'EOF'
{
  "schemaVersion": 1,
  "skillSets": {"aad": [], "general": ["agent-pipeline-feedback"]},
  "legacyCleanup": {"aad": 0, "general": 0}
}
EOF
pi_setup_install_skills "$fixture" "$legacy_owner_agent" aad >/dev/null
test -f "$legacy_owner_agent/skills/agent-pipeline-feedback/SKILL.md" || \
  fail "AAD legacy cleanup removed unselected manifest ownership"

# The public installer refuses to overwrite an unowned exact destination,
# including a newly generalized name even when legacy adoption is requested.
conflict_agent="$tmp_root/conflict-agent"
mkdir -p "$conflict_agent/skills/backend-quality"
printf 'external backend quality\n' > "$conflict_agent/skills/backend-quality/SKILL.md"
cp "$conflict_agent/skills/backend-quality/SKILL.md" "$tmp_root/backend-quality.before"
expect_install_failure "$fixture" "$conflict_agent" general
expect_install_failure "$fixture" "$conflict_agent" all --adopt-legacy
cmp -s "$tmp_root/backend-quality.before" \
  "$conflict_agent/skills/backend-quality/SKILL.md" || fail "unowned same-name skill changed"
test ! -e "$conflict_agent/.pi-agent-setup-skills.json" || fail "conflict wrote ownership manifest"

# Combined full-updater migration publishes all nested sources, adopts only
# unchanged identities it historically owned, cleans explicit legacy names,
# and preserves executable helper scripts.
all_agent="$tmp_root/all-agent"
mkdir -p \
  "$all_agent/skills/aad-git-branching" \
  "$all_agent/skills/aad-quality-frontend" \
  "$all_agent/skills/aad-target-branch-preparation" \
  "$all_agent/skills/browser-chrome" \
  "$all_agent/skills/visual-composition-quality"
printf 'old managed browser\n' > "$all_agent/skills/browser-chrome/SKILL.md"
pi_setup_install_skills "$fixture" "$all_agent" all --adopt-legacy >/dev/null
[ "$(find "$all_agent/skills" -mindepth 1 -maxdepth 1 -type d | wc -l)" -eq 14 ] || fail "all did not flatten 14 skills"
test ! -e "$all_agent/skills/aad-git-branching" || fail "renamed Git branching legacy survived"
test ! -e "$all_agent/skills/aad-quality-frontend" || fail "renamed frontend legacy survived"
test ! -e "$all_agent/skills/aad-target-branch-preparation" || fail "historical AAD legacy survived"
test ! -e "$all_agent/skills/visual-composition-quality" || fail "historical general legacy survived"
test -x "$all_agent/skills/git-branching/scripts/prepare-target-branch.sh" || fail "prepare helper lost executable mode"
test -x "$all_agent/skills/git-branching/scripts/sync-target-branch.sh" || fail "sync helper lost executable mode"
"$all_agent/skills/git-branching/scripts/prepare-target-branch.sh" >/dev/null || fail "installed prepare helper did not execute"
"$all_agent/skills/git-branching/scripts/sync-target-branch.sh" >/dev/null || fail "installed sync helper did not execute"
grep -Fq 'name: browser-chrome' "$all_agent/skills/browser-chrome/SKILL.md" || fail "legacy browser was not adopted"
assert_manifest_set "$all_agent/.pi-agent-setup-skills.json" aad 5 1
assert_manifest_set "$all_agent/.pi-agent-setup-skills.json" common 1 1
assert_manifest_set "$all_agent/.pi-agent-setup-skills.json" general 8 1

# The full asset path still installs agents/extensions but no longer performs
# broad skill deletion or recursively rewrites unrelated/managed skill modes.
full_agent="$tmp_root/full-agent"
mkdir -p \
  "$full_agent/agents" \
  "$full_agent/skills/aad-user-owned/bin"
printf 'custom\n' > "$full_agent/agents/custom-agent.md"
printf 'stale\n' > "$full_agent/agents/aad-stale.md"
printf 'user\n' > "$full_agent/skills/aad-user-owned/SKILL.md"
printf '#!/bin/sh\n' > "$full_agent/skills/aad-user-owned/bin/tool"
printf '#!/bin/sh\n' > "$full_agent/skills/aad-user-owned/manual.sh"
chmod 755 "$full_agent/skills/aad-user-owned/bin/tool"
chmod 644 "$full_agent/skills/aad-user-owned/manual.sh"
pi_setup_install_assets "$fixture" "$full_agent"
pi_setup_install_skills "$fixture" "$full_agent" all --adopt-legacy >/dev/null
pi_setup_secure_assets "$full_agent" "$tmp_root"
test -f "$full_agent/agents/custom-agent.md" || fail "custom agent was removed"
test ! -e "$full_agent/agents/aad-stale.md" || fail "stale managed agent survived"
test -f "$full_agent/skills/aad-user-owned/SKILL.md" || fail "broad aad-* skill deletion remains"
[ "$(stat -c '%a' "$full_agent/skills/aad-user-owned/bin/tool")" = 755 ] || fail "custom executable mode changed"
[ "$(stat -c '%a' "$full_agent/skills/aad-user-owned/manual.sh")" = 644 ] || fail "custom shell mode changed"
[ "$(stat -c '%a' "$full_agent/skills/git-branching/scripts/prepare-target-branch.sh")" = 755 ] || fail "managed prepare helper mode changed"
[ "$(stat -c '%a' "$full_agent/skills/git-branching/scripts/sync-target-branch.sh")" = 755 ] || fail "managed sync helper mode changed"

# Unknown sets fail before target mutation in both the shared function and the
# public entrypoint.
unknown_target="$tmp_root/unknown-agent"
expect_install_failure "$fixture" "$unknown_target" unknown
test ! -e "$unknown_target" || fail "unknown set mutated target"
cli_unknown_target="$tmp_root/cli-unknown-agent"
if PI_AGENT_DIR="$cli_unknown_target" "$repo_root/scripts/install-skills.sh" --set unknown >/dev/null 2>&1; then
  fail "public installer accepted unknown set"
fi
test ! -e "$cli_unknown_target" || fail "public unknown set mutated target"

# Duplicate runtime destinations and invalid frontmatter fail before mutation.
collision_repo="$tmp_root/collision-repo"
cp -a "$fixture" "$collision_repo"
write_skill "$collision_repo" aad nested/backend-quality backend-quality
invalid_target="$tmp_root/invalid-agent"
mkdir -p "$invalid_target/skills/sentinel"
printf 'keep\n' > "$invalid_target/skills/sentinel/SKILL.md"
expect_install_failure "$collision_repo" "$invalid_target" all
test -f "$invalid_target/skills/sentinel/SKILL.md" || fail "collision changed existing installation"
test ! -e "$invalid_target/.pi-agent-setup-skills.json" || fail "collision wrote manifest"

frontmatter_repo="$tmp_root/frontmatter-repo"
cp -a "$fixture" "$frontmatter_repo"
printf '%s\n' '---' 'name: backend-quality' '---' > \
  "$frontmatter_repo/skills/general/group/backend-quality/SKILL.md"
expect_install_failure "$frontmatter_repo" "$invalid_target" general

cat > "$frontmatter_repo/skills/general/group/backend-quality/SKILL.md" <<'EOF'
---
name: ../unsafe
description: Invalid unsafe name.
---
EOF
expect_install_failure "$frontmatter_repo" "$invalid_target" general

yaml_repo="$tmp_root/yaml-repo"
cp -a "$fixture" "$yaml_repo"
sed -i 's/^description:.*/description: malformed: yaml/' \
  "$yaml_repo/skills/general/group/backend-quality/SKILL.md"
expect_install_failure "$yaml_repo" "$invalid_target" general
test ! -e "$invalid_target/.pi-agent-setup-skills.json" || fail "invalid YAML wrote manifest"
sed -i 's/^description:.*/description: # YAML null, not a string/' \
  "$yaml_repo/skills/general/group/backend-quality/SKILL.md"
expect_install_failure "$yaml_repo" "$invalid_target" general
sed -i 's/^description:.*/description: "quoted: yaml"/' \
  "$yaml_repo/skills/general/group/backend-quality/SKILL.md"
quoted_target="$tmp_root/quoted-target"
pi_setup_install_skills "$yaml_repo" "$quoted_target" general >/dev/null
test -f "$quoted_target/skills/backend-quality/SKILL.md" || fail "quoted YAML scalar was rejected"

mismatch_repo="$tmp_root/mismatch-repo"
cp -a "$fixture" "$mismatch_repo"
sed -i 's/name: backend-quality/name: different-name/' \
  "$mismatch_repo/skills/general/group/backend-quality/SKILL.md"
expect_install_failure "$mismatch_repo" "$invalid_target" general

coupled_repo="$tmp_root/coupled-repo"
cp -a "$fixture" "$coupled_repo"
printf '\nUse the AAD task package.\n' >> \
  "$coupled_repo/skills/general/group/backend-quality/SKILL.md"
expect_install_failure "$coupled_repo" "$invalid_target" general

# Escaping source roots, symlinked targets, and symlinked exact destinations
# fail closed without following attacker-controlled paths.
escaped_repo="$tmp_root/escaped-repo"
cp -a "$fixture" "$escaped_repo"
rm -rf "$escaped_repo/skills/general"
ln -s "$tmp_root" "$escaped_repo/skills/general"
expect_install_failure "$escaped_repo" "$invalid_target" general

real_target="$tmp_root/real-target"
symlink_target="$tmp_root/symlink-target"
mkdir -p "$real_target/skills"
printf 'keep\n' > "$real_target/keep.txt"
ln -s "$real_target" "$symlink_target"
expect_install_failure "$fixture" "$symlink_target" general
test -f "$real_target/keep.txt" || fail "symlinked target was followed"

unsafe_destination="$tmp_root/unsafe-destination"
external_destination="$tmp_root/external-destination"
mkdir -p "$unsafe_destination/skills" "$external_destination"
printf 'external\n' > "$external_destination/keep.txt"
ln -s "$external_destination" "$unsafe_destination/skills/backend-quality"
expect_install_failure "$fixture" "$unsafe_destination" general
test -f "$external_destination/keep.txt" || fail "symlinked destination was followed"
test ! -e "$unsafe_destination/.pi-agent-setup-skills.json" || fail "unsafe destination wrote manifest"

# The updater consumes the same shared all-set implementation and moved source.
grep -Fq 'pi_setup_initialize_skill_sources "$repo_root" all' "$repo_root/scripts/update-local.sh" || fail "update-local does not initialize set=all"
grep -Fq 'pi_setup_install_skills "$repo_root" "$AGENT_DIR" all --adopt-legacy' "$repo_root/scripts/update-local.sh" || fail "update-local does not perform bounded legacy adoption"
grep -Fq 'skills/general/browser-chrome' "$repo_root/scripts/lib/local-assets.sh" || fail "skill source initialization uses the old Browser Chrome path"

if rg -n 'python3?[[:space:]]+-([[:space:]]|$)|<<.*PY' \
  "$repo_root/scripts/update-local.sh" "$repo_root/scripts/lib" -g '*.sh'; then
  fail "embedded Python found in production shell"
fi

printf 'local asset tests passed\n'
