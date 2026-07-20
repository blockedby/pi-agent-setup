#!/usr/bin/env bash

pi_setup_deploy_static_assets() {
  local source_root="$1" agent_dir="$2" user_home="$3" subagent_config="$4" skill_sync="$5"
  mkdir -p "$agent_dir/agents" "$agent_dir/extensions" "$agent_dir/extensions/subagent" "$agent_dir/skills"
  install -m 0644 "$source_root/APPEND_SYSTEM.md" "$agent_dir/APPEND_SYSTEM.md"
  install -m 0644 "$source_root/agents/"*.md "$agent_dir/agents/"
  install -m 0644 "$source_root/extensions/"*.ts "$agent_dir/extensions/"
  install -m 0644 "$subagent_config" "$agent_dir/extensions/subagent/config.json"
  case "$skill_sync" in
    merge) rsync -a "$source_root/skills/" "$agent_dir/skills/" ;;
    replace) rsync -a --delete "$source_root/skills/" "$agent_dir/skills/" ;;
    *) echo "Unknown skill sync policy: $skill_sync" >&2; return 2 ;;
  esac
  pi_setup_remove_stale_agents "$agent_dir" "$user_home"
}

pi_setup_replace_settings() {
  local settings_source="$1" agent_dir="$2"
  if [ -f "$agent_dir/settings.json" ]; then
    cp -a "$agent_dir/settings.json" "$agent_dir/settings.json.bak.$(date -u +%Y%m%dT%H%M%SZ)"
  fi
  install -m 0644 "$settings_source" "$agent_dir/settings.json"
}

pi_setup_remove_stale_agents() {
  local agent_dir="$1" user_home="$2" stale
  for stale in \
    tdd-coder.md implementer.md failure-classifier.md \
    aad-test-auditor.md aad-reviewer.md quinn-validator.md; do
    rm -f "$agent_dir/agents/$stale" "$user_home/.agents/$stale"
  done
}

pi_setup_secure_agent_assets() {
  local agent_dir="$1" user_home="$2"
  chmod 700 "$user_home/.pi" "$agent_dir" "$agent_dir/agents" "$agent_dir/extensions" "$agent_dir/skills"
  chmod 600 "$agent_dir/APPEND_SYSTEM.md" "$agent_dir/agents/"*.md "$agent_dir/extensions/"*.ts
  find "$agent_dir/skills" -type d -exec chmod 700 {} +
  find "$agent_dir/skills" -type f -exec chmod 600 {} +
  find "$agent_dir/skills/browser-chrome/scripts" -type f -name '*.sh' -exec chmod 700 {} + 2>/dev/null || true
  [ ! -f "$agent_dir/mcp.json" ] || chmod 600 "$agent_dir/mcp.json"
  [ ! -f "$agent_dir/settings.json" ] || chmod 600 "$agent_dir/settings.json"
  [ ! -f "$agent_dir/extensions/subagent/config.json" ] || chmod 600 "$agent_dir/extensions/subagent/config.json"
}
