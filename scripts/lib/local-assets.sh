#!/usr/bin/env bash

pi_setup_require_skill_set() {
  case "${1:-}" in
    general|aad|all) ;;
    *) echo "Unknown skill set: ${1:-<missing>} (expected general, aad, or all)" >&2; return 2 ;;
  esac
}

pi_setup_initialize_skill_sources() {
  local repo_root="$1" set_name="$2"
  pi_setup_require_skill_set "$set_name" || return

  case "$set_name" in
    general|all)
      if [ ! -f "$repo_root/skills/general/browser-chrome/SKILL.md" ]; then
        "${GIT_BIN:-git}" -C "$repo_root" submodule update --init --recursive \
          skills/general/browser-chrome
      fi
      ;;
  esac
}

pi_setup_validate_skill_target() {
  local repo_root="$1" agent_dir="$2"
  python3 "$repo_root/scripts/lib/skill-assets.py" validate-target "$agent_dir"
}

pi_setup_validate_asset_target() {
  local repo_root="$1" agent_dir="$2" managed
  pi_setup_validate_skill_target "$repo_root" "$agent_dir"
  for managed in "$agent_dir/agents" "$agent_dir/extensions" "$agent_dir/extensions/subagent"; do
    [ ! -L "$managed" ] || {
      echo "Refusing symlinked managed directory: $managed" >&2
      return 1
    }
  done
}

pi_setup_validate_skills() {
  local repo_root="$1" set_name="${2:-all}"
  pi_setup_require_skill_set "$set_name" || return
  python3 "$repo_root/scripts/lib/skill-assets.py" validate-profile "$repo_root" "$set_name" >/dev/null
}

pi_setup_install_skills() {
  local repo_root="$1" agent_dir="$2" set_name="$3" migration_mode="${4:-}"
  pi_setup_require_skill_set "$set_name" || return
  case "$migration_mode" in
    "")
      python3 "$repo_root/scripts/lib/skill-assets.py" install \
        "$repo_root" "$agent_dir" "$set_name"
      ;;
    --adopt-legacy)
      python3 "$repo_root/scripts/lib/skill-assets.py" install \
        "$repo_root" "$agent_dir" "$set_name" --adopt-legacy
      ;;
    *)
      echo "Unknown skill migration mode: $migration_mode" >&2
      return 2
      ;;
  esac
}

pi_setup_count_skills() {
  local repo_root="$1" set_name="${2:-all}"
  pi_setup_require_skill_set "$set_name" || return
  python3 "$repo_root/scripts/lib/skill-assets.py" validate-source "$repo_root" "$set_name"
}

pi_setup_validate_assets() {
  local repo_root="$1" set_name="${2:-all}" file
  local -a agents=("$repo_root"/agents/*.md)

  [ -f "$repo_root/APPEND_SYSTEM.md" ] || { echo "Missing APPEND_SYSTEM.md" >&2; return 1; }
  [ -f "$repo_root/settings/pi-subagents.config.json" ] || { echo "Missing pi-subagents config" >&2; return 1; }

  for file in "${agents[@]}"; do
    [ -f "$file" ] || { echo "Missing agent files" >&2; return 1; }
    grep -Eq '^name:[[:space:]]*[^[:space:]]' "$file" || { echo "Missing name in $file" >&2; return 1; }
    grep -Eq '^description:[[:space:]]*[^[:space:]]' "$file" || { echo "Missing description in $file" >&2; return 1; }
  done

  if grep -R --line-number --fixed-strings codex_task "$repo_root/agents"; then
    echo "codex_task must not be exposed by checked-in agents" >&2
    return 1
  fi

  pi_setup_validate_skills "$repo_root" "$set_name"
}

pi_setup_install_assets() {
  local repo_root="$1" agent_dir="$2"
  local stale
  local -a agents=("$repo_root"/agents/*.md)
  local -a extensions=("$repo_root"/extensions/*.ts)

  pi_setup_validate_asset_target "$repo_root" "$agent_dir"
  mkdir -p "$agent_dir/agents" "$agent_dir/extensions/subagent" "$agent_dir/skills"

  # Agent ownership remains namespace-based for compatibility. Skill ownership
  # is handled separately by the exact set-aware manifest.
  find "$agent_dir/agents" -maxdepth 1 -type f -name 'aad-*.md' -delete
  rm -f "$agent_dir/agents/chrome-browser-agent.md"
  for stale in \
    tdd-coder.md \
    implementer.md \
    failure-classifier.md \
    aad-reviewer.md \
    quinn-validator.md \
    visual-critic.md; do
    rm -f "$agent_dir/agents/$stale"
  done

  install -m 0600 "$repo_root/APPEND_SYSTEM.md" "$agent_dir/APPEND_SYSTEM.md"
  install -m 0600 "${agents[@]}" "$agent_dir/agents/"
  install -m 0600 "${extensions[@]}" "$agent_dir/extensions/"
  install -m 0600 "$repo_root/settings/pi-subagents.config.json" "$agent_dir/extensions/subagent/config.json"
}

pi_setup_install_full_assets() {
  local repo_root="$1" agent_dir="$2"
  # Validate every managed target before the first mutation. Skill publication
  # then runs before agent/extension replacement so ownership conflicts fail
  # without leaving a partially updated AAD setup.
  pi_setup_validate_asset_target "$repo_root" "$agent_dir" || return
  pi_setup_install_skills "$repo_root" "$agent_dir" all --adopt-legacy >/dev/null || return
  pi_setup_install_assets "$repo_root" "$agent_dir"
}

pi_setup_secure_assets() {
  local agent_dir="$1" user_home="$2"
  [ ! -d "$user_home/.pi" ] || chmod 700 "$user_home/.pi"
  chmod 700 "$agent_dir" "$agent_dir/agents" "$agent_dir/extensions" "$agent_dir/skills"
  find "$agent_dir/agents" "$agent_dir/extensions" -type d -exec chmod 700 {} +
  find "$agent_dir/agents" "$agent_dir/extensions" -type f -exec chmod 600 {} +
  [ ! -f "$agent_dir/mcp.json" ] || chmod 600 "$agent_dir/mcp.json"
  [ ! -f "$agent_dir/settings.json" ] || chmod 600 "$agent_dir/settings.json"
  [ ! -f "$agent_dir/.pi-agent-setup-skills.json" ] || chmod 600 "$agent_dir/.pi-agent-setup-skills.json"
}
