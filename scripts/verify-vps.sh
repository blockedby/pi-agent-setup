#!/usr/bin/env bash
set -euo pipefail

TARGET_HOST="${TARGET_HOST:-nl-2-nvme}"
REMOTE_USER_HOME="${REMOTE_USER_HOME:-}"
ssh "$TARGET_HOST" bash -s -- "$REMOTE_USER_HOME" <<'REMOTE'
set -euo pipefail
REQUESTED_REMOTE_USER_HOME="$1"

if [ -n "$REQUESTED_REMOTE_USER_HOME" ]; then
  if [ -d "$REQUESTED_REMOTE_USER_HOME" ]; then
    REMOTE_USER_HOME="$REQUESTED_REMOTE_USER_HOME"
  else
    REMOTE_USER_HOME="/root"
  fi
elif [ -n "${HOME:-}" ] && [ -d "$HOME" ]; then
  REMOTE_USER_HOME="$HOME"
else
  REMOTE_USER_HOME="/root"
fi

VP_BIN_DIR="$REMOTE_USER_HOME/.vite-plus/bin"
AGENT_DIR="$REMOTE_USER_HOME/.pi/agent"
export PATH="$VP_BIN_DIR:$PATH"

echo "== resolved home =="
echo "$REMOTE_USER_HOME"

echo '== vite/node/npm/pi =='
"$VP_BIN_DIR/node" --version
"$VP_BIN_DIR/npm" --version
"$VP_BIN_DIR/pi" --version
"$VP_BIN_DIR/codex" --version

echo '== pi files =='
test -f "$AGENT_DIR/settings.json"
test -f "$AGENT_DIR/APPEND_SYSTEM.md"
grep -q "aad-root-owner" "$AGENT_DIR/APPEND_SYSTEM.md"
grep -q "aad-slice-owner" "$AGENT_DIR/APPEND_SYSTEM.md"
test -d "$AGENT_DIR/agents"
test -d "$AGENT_DIR/skills"
find "$AGENT_DIR/agents" -maxdepth 1 -type f -name '*.md' -printf '%f\n' | sort
find "$AGENT_DIR/skills" -maxdepth 2 -type f -path '*/SKILL.md' -printf '%h\n' | sed "s#^$AGENT_DIR/skills/##" | sort

for required in \
  aad-explorer.md \
  aad-root-owner.md \
  aad-slice-owner.md \
  aad-acceptance-auditor.md \
  aad-implementer.md \
  aad-failure-classifier.md \
  chrome-browser-agent.md \
  aad-discovery-plan.chain.md \
  aad-owned-change.chain.md \
  aad-problem-investigation.chain.md; do
  test -f "$AGENT_DIR/agents/$required"
done

for stale in \
  tdd-coder.md \
  implementer.md \
  failure-classifier.md \
  aad-test-auditor.md \
  aad-reviewer.md \
  quinn-validator.md \
  aad-parallel-investigation.chain.md; do
  for stale_dir in "$AGENT_DIR/agents" "$REMOTE_USER_HOME/.agents"; do
    if [ -e "$stale_dir/$stale" ]; then
      echo "stale executable agent/chain still installed: $stale_dir/$stale" >&2
      exit 1
    fi
  done
done

for required in \
  aad-design-refinement \
  aad-failure-classification \
  aad-implementation-report \
  aad-integration \
  aad-plan-writing \
  aad-reporting \
  aad-review-handling \
  aad-slicing-and-delegation \
  aad-systematic-debugging \
  aad-target-branch-preparation \
  aad-task-package \
  aad-verification \
  aad-worktree-management \
  browser-chrome; do
  test -f "$AGENT_DIR/skills/$required/SKILL.md"
done

echo '== pi packages =='
"$VP_BIN_DIR/pi" list | sed -n '1,160p'

echo '== smoke =='
timeout "${PI_SMOKE_TIMEOUT_SECONDS:-900}" "$VP_BIN_DIR/pi" --no-session --mode text -p 'Say OK and exit.' | tail -n 40
REMOTE
