#!/usr/bin/env bash

pi_setup_validate_assets() {
  local repo_root="$1" file
  local -a agents=("$repo_root"/agents/*.md)
  local -a skills=("$repo_root"/skills/*/SKILL.md)

  [ -f "$repo_root/APPEND_SYSTEM.md" ] || { echo "Missing APPEND_SYSTEM.md" >&2; return 1; }
  [ -f "$repo_root/settings/pi-subagents.config.json" ] || { echo "Missing pi-subagents config" >&2; return 1; }

  for file in "${agents[@]}" "${skills[@]}"; do
    [ -f "$file" ] || { echo "Missing agent or skill files" >&2; return 1; }
    grep -Eq '^name:[[:space:]]*[^[:space:]]' "$file" || { echo "Missing name in $file" >&2; return 1; }
    grep -Eq '^description:[[:space:]]*[^[:space:]]' "$file" || { echo "Missing description in $file" >&2; return 1; }
  done

  if grep -R --line-number --fixed-strings codex_task "$repo_root/agents"; then
    echo "codex_task must not be exposed by checked-in agents" >&2
    return 1
  fi
}

pi_setup_install_assets() {
  local repo_root="$1" agent_dir="$2"
  local source target stale
  local -a agents=("$repo_root"/agents/*.md)
  local -a extensions=("$repo_root"/extensions/*.ts)

  [ ! -L "$agent_dir" ] || { echo "Refusing symlinked Pi agent directory: $agent_dir" >&2; return 1; }
  mkdir -p "$agent_dir/agents" "$agent_dir/extensions/subagent" "$agent_dir/skills"

  # This repository owns aad-* plus chrome-browser-agent. Other user agents and
  # skills are preserved.
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

  find "$agent_dir/skills" -mindepth 1 -maxdepth 1 -name 'aad-*' -exec rm -rf -- {} +
  # These non-aad directories were owned by this repository at 3f4a842 and
  # have since been removed or replaced. External skills are not touched.
  for stale in \
    21st-magic-mcp \
    acceptance-evidence-gate \
    agent-pipeline-feedback \
    backend-api-data-quality \
    browser-visual-report \
    devops-runtime-readiness \
    frontend-ui-quality \
    visual-composition-quality; do
    rm -rf "$agent_dir/skills/$stale"
  done
  for source in "$repo_root"/skills/*; do
    [ -f "$source/SKILL.md" ] || continue
    target="$agent_dir/skills/$(basename "$source")"
    rm -rf "$target"
    mkdir -p "$target"
    rsync -a --delete --exclude='.git' "$source/" "$target/"
  done
}

pi_setup_secure_assets() {
  local agent_dir="$1" user_home="$2"
  [ ! -d "$user_home/.pi" ] || chmod 700 "$user_home/.pi"
  chmod 700 "$agent_dir" "$agent_dir/agents" "$agent_dir/extensions" "$agent_dir/skills"
  find "$agent_dir/agents" "$agent_dir/extensions" "$agent_dir/skills" -type f -exec chmod 600 {} +
  find "$agent_dir/skills" -type d -exec chmod 700 {} +
  find "$agent_dir/skills" -type f -name '*.sh' -exec chmod 700 {} +
  [ ! -f "$agent_dir/mcp.json" ] || chmod 600 "$agent_dir/mcp.json"
  [ ! -f "$agent_dir/settings.json" ] || chmod 600 "$agent_dir/settings.json"
}
