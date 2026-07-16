#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT/scripts/aad-finalization-helper.sh"
run_helper() { bash "$SCRIPT" target-branch-prepare "$@"; }
AAD_TARGET_BRANCH_PREPARATION_SCRIPTS_DIR="$ROOT/scripts" run_helper --help >/dev/null
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
commit() { git -C "$1" add .; git -C "$1" -c user.name=test -c user.email=test@example.invalid commit -m "$2" >/dev/null; }
git init --bare "$tmp/origin.git" >/dev/null; git clone "$tmp/origin.git" "$tmp/work" >/dev/null 2>&1
w="$tmp/work"; git -C "$w" checkout -b main >/dev/null; echo base >"$w/base"; commit "$w" base; git -C "$w" push -u origin main >/dev/null
git -C "$w" checkout -b feature/test >/dev/null; echo feature >"$w/feature"; commit "$w" feature
before_remote="$(git -C "$w" rev-parse origin/main)"; out="$(cd "$w" && run_helper)"; [[ "$out" == *'rebase_status=up_to_date'* && "$out" == *'content_changed=false'* && "$out" == *'rerun_required=false'* ]]; [[ "$(git -C "$w" rev-parse origin/main)" == "$before_remote" ]]
git clone "$tmp/origin.git" "$tmp/peer" >/dev/null 2>&1; git -C "$tmp/peer" checkout main >/dev/null; echo remote >"$tmp/peer/remote"; commit "$tmp/peer" remote; git -C "$tmp/peer" push origin main >/dev/null
out="$(cd "$w" && run_helper)"; [[ "$out" == *'rebase_status=rebased'* && "$out" == *'content_changed=true'* && "$out" == *'rerun_required=true'* ]]; [[ -f "$w/remote" ]]
printf 'target-branch-prepare tests passed\n'
