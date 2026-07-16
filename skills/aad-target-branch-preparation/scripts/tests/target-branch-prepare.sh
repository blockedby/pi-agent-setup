#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; SCRIPT="$ROOT/scripts/aad-finalization-helper.sh"
run() { AAD_TARGET_BRANCH_PREPARATION_SCRIPTS_DIR="$ROOT/scripts" bash "$SCRIPT" target-branch-prepare "$@"; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
commit(){ git -C "$1" add .; git -C "$1" -c user.name=test -c user.email=test@example.invalid commit -m "$2" >/dev/null; }
new_repo(){ local n="$1" target="$2"; git init --bare "$tmp/$n.git" >/dev/null; git clone "$tmp/$n.git" "$tmp/$n" >/dev/null 2>&1; git -C "$tmp/$n" checkout -b "$target" >/dev/null; echo base >"$tmp/$n/base"; commit "$tmp/$n" base; git -C "$tmp/$n" push -u origin "$target" >/dev/null; }
# Reflog provenance infers dev and never mutates remote.
new_repo dev dev; w="$tmp/dev"; git -C "$w" checkout -b feature/reflog dev >/dev/null; echo f >"$w/f"; commit "$w" f; before="$(git -C "$w" rev-parse origin/dev)"; out="$(cd "$w" && run)"; [[ "$out" == *$'target_branch=dev'* && "$out" == *'rebase_status=up_to_date'* ]]; [[ "$(git -C "$w" rev-parse origin/dev)" == "$before" ]]
# Explicit stage target overrides recorded provenance.
new_repo stage stage; w="$tmp/stage"; git -C "$w" checkout -b dev >/dev/null; git -C "$w" push -u origin dev >/dev/null; git -C "$w" checkout -b feature/override dev >/dev/null; echo f >"$w/f"; commit "$w" f; out="$(cd "$w" && run --target stage)"; [[ "$out" == *$'target_branch=stage'* ]]
# Config provenance works even when reflog is unavailable/ambiguous.
new_repo config dev; w="$tmp/config"; git -C "$w" checkout -b feature/config dev >/dev/null; git -C "$w" config branch.feature/config.aadTarget dev; echo f >"$w/f"; commit "$w" f; out="$(cd "$w" && run)"; [[ "$out" == *$'target_branch=dev'* ]]
# Unresolved provenance fails closed and does not contact/mutate remote.
new_repo unresolved dev; w="$tmp/unresolved"; git -C "$w" checkout --orphan feature/orphan >/dev/null; git -C "$w" rm -rf . >/dev/null 2>&1 || true; echo f >"$w/f"; commit "$w" f; before="$(git -C "$w" ls-remote origin refs/heads/dev | awk '{print $1}')"; if out="$(cd "$w" && run 2>&1)"; then exit 1; fi; [[ "$out" == *'cannot infer target branch'* ]]; [[ "$(git -C "$w" ls-remote origin refs/heads/dev | awk '{print $1}')" == "$before" ]]
printf 'target-branch-prepare provenance tests passed\n'
