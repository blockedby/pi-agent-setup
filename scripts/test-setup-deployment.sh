#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT
fail() { echo "setup deployment test failed: $*" >&2; exit 1; }

# shellcheck source=lib/setup-deployment.sh
source "$repo_root/scripts/lib/setup-deployment.sh"
# shellcheck source=lib/setup-verification.sh
source "$repo_root/scripts/lib/setup-verification.sh"

source_root="$tmp_root/source"
mkdir -p "$source_root/agents" "$source_root/extensions" "$source_root/skills/managed"
printf 'prompt\n' > "$source_root/APPEND_SYSTEM.md"
printf '%s\n' '---' 'name: managed' > "$source_root/agents/managed.md"
printf 'export {}\n' > "$source_root/extensions/managed.ts"
printf '%s\n' '---' 'name: managed' > "$source_root/skills/managed/SKILL.md"
printf '{}\n' > "$tmp_root/subagents.json"

local_home="$tmp_root/local-home"
local_agent="$local_home/.pi/agent"
mkdir -p "$local_agent/skills/custom"
printf 'custom\n' > "$local_agent/skills/custom/SKILL.md"
pi_setup_deploy_static_assets "$source_root" "$local_agent" "$local_home" "$tmp_root/subagents.json" merge
test -f "$local_agent/skills/custom/SKILL.md" || fail 'merge sync removed a custom local skill'
test -f "$local_agent/skills/managed/SKILL.md" || fail 'merge sync did not deploy managed skill'

remote_home="$tmp_root/remote-home"
remote_agent="$remote_home/.pi/agent"
mkdir -p "$remote_agent/skills/stale"
printf 'stale\n' > "$remote_agent/skills/stale/SKILL.md"
pi_setup_deploy_static_assets "$source_root" "$remote_agent" "$remote_home" "$tmp_root/subagents.json" replace
test ! -e "$remote_agent/skills/stale" || fail 'replace sync retained stale remote skill'
test -f "$remote_agent/skills/managed/SKILL.md" || fail 'replace sync did not deploy managed skill'

# The manifest is the verifier contract and must exactly match installation
# sources. Ordinary skill directories must contain SKILL.md; browser-chrome is
# accepted only because Git records it as a submodule gitlink when uninitialized.
compare_sorted_sets() {
  local label="$1"
  shift
  local -a manifest=("${!1}") source=("${!2}")
  if ! diff -u \
    <(printf '%s\n' "${manifest[@]}" | LC_ALL=C sort) \
    <(printf '%s\n' "${source[@]}" | LC_ALL=C sort); then
    fail "$label manifest does not exactly match installation source"
  fi
}

mapfile -t source_agents < <(
  find "$repo_root/agents" -maxdepth 1 -type f -name '*.md' -printf '%f\n' | LC_ALL=C sort
)
mapfile -t source_skills < <(
  {
    find "$repo_root/skills" -mindepth 2 -maxdepth 2 -type f -name SKILL.md -printf '%h\n' |
      sed "s#^$repo_root/skills/##"
    git -C "$repo_root" ls-files --stage -- skills |
      awk '$1 == "160000" { sub("skills/", "", $4); print $4 }'
  } | LC_ALL=C sort -u
)
compare_sorted_sets 'agent' PI_SETUP_REQUIRED_AGENTS[@] source_agents[@]
compare_sorted_sets 'skill' PI_SETUP_REQUIRED_SKILLS[@] source_skills[@]

installed_home="$tmp_root/installed-home"
installed_agent="$installed_home/.pi/agent"
for required in "${PI_SETUP_REQUIRED_AGENTS[@]}"; do
  mkdir -p "$installed_agent/agents"
  touch "$installed_agent/agents/$required"
done
for required in "${PI_SETUP_REQUIRED_SKILLS[@]}"; do
  mkdir -p "$installed_agent/skills/$required"
  touch "$installed_agent/skills/$required/SKILL.md"
done
pi_setup_verify_agents "$installed_agent" "$installed_home"
printf '%s\n' 'setup deployment tests passed'
