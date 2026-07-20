#!/usr/bin/env bash

# shellcheck source=setup-assets.sh
source "$(dirname "${BASH_SOURCE[0]}")/setup-assets.sh"

pi_setup_verify_agents() {
  local agent_dir="$1" user_home="$2" required stale stale_dir
  for required in "${PI_SETUP_REQUIRED_AGENTS[@]}"; do
    test -f "$agent_dir/agents/$required"
  done
  for stale in \
    tdd-coder.md implementer.md failure-classifier.md \
    aad-test-auditor.md aad-reviewer.md quinn-validator.md; do
    for stale_dir in "$agent_dir/agents" "$user_home/.agents"; do
      if [ -e "$stale_dir/$stale" ]; then
        echo "stale executable agent still installed: $stale_dir/$stale" >&2
        return 1
      fi
    done
  done
  for required in "${PI_SETUP_REQUIRED_SKILLS[@]}"; do
    test -f "$agent_dir/skills/$required/SKILL.md"
  done
}
