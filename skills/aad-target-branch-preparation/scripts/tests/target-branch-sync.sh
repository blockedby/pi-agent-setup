#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"; SCRIPT="$ROOT/scripts/aad-finalization-helper.sh"
run(){ AAD_TARGET_BRANCH_PREPARATION_SCRIPTS_DIR="$ROOT/scripts" bash "$SCRIPT" target-branch-sync "$@"; }
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
commit(){ git -C "$1" add .; git -C "$1" -c user.name=test -c user.email=test@example.invalid commit -m "$2" >/dev/null; }
new_repo(){ local n="$1" target="$2"; git init --bare "$tmp/$n.git" >/dev/null; git clone "$tmp/$n.git" "$tmp/$n-root" >/dev/null 2>&1; local r="$tmp/$n-root"; git -C "$r" checkout -b "$target" >/dev/null; echo base >"$r/base"; commit "$r" base; git -C "$r" push -u origin "$target" >/dev/null; printf '%s\n' "$r"; }
advance(){ local r="$1" peer="$2" target="$3"; git clone "$(git -C "$r" remote get-url origin)" "$peer" >/dev/null 2>&1; git -C "$peer" checkout "$target" >/dev/null; echo remote >"$peer/remote"; commit "$peer" remote; git -C "$peer" push origin "$target" >/dev/null; }
remote_head(){ git -C "$1" ls-remote origin "refs/heads/$2" | awk '{print $1}'; }
# Equal stage uses current target checkout default and never mutates remote.
r="$(new_repo equal stage)"; before="$(remote_head "$r" stage)"; out="$(cd "$r" && run)"; [[ "$out" == *'target_branch=stage'* && "$out" == *'sync_status=up_to_date'* ]]; [[ "$(remote_head "$r" stage)" == "$before" ]]
# Behind dev fast-forwards only.
r="$(new_repo behind dev)"; advance "$r" "$tmp/behind-peer" dev; before="$(remote_head "$r" dev)"; out="$(cd "$r" && run --target dev)"; [[ "$out" == *'sync_status=fast_forwarded'* ]]; [[ "$(git -C "$r" rev-parse HEAD)" == "$before" ]]; [[ "$(remote_head "$r" dev)" == "$before" ]]
# Dirty refuses before requested cleanup or remote mutation.
r="$(new_repo dirty dev)"; git -C "$r" worktree add -b feature/dirty "$tmp/dirty-feature" >/dev/null; echo f >"$tmp/dirty-feature/f"; commit "$tmp/dirty-feature" f; echo dirty >>"$r/base"; before="$(remote_head "$r" dev)"; if out="$(cd "$r" && run --delete-worktree "$tmp/dirty-feature" --delete-branch feature/dirty 2>&1)"; then exit 1; fi; [[ "$out" == *'sync_status=rejected'* ]]; [[ -d "$tmp/dirty-feature" ]]; [[ "$(remote_head "$r" dev)" == "$before" ]]
# Ahead and diverged reject without cleanup or publishing.
r="$(new_repo ahead stage)"; echo local >"$r/local"; commit "$r" local; h="$(git -C "$r" rev-parse HEAD)"; before="$(remote_head "$r" stage)"; if out="$(cd "$r" && run --target stage 2>&1)"; then exit 1; fi; [[ "$out" == *'ahead=1'* ]]; [[ "$(git -C "$r" rev-parse HEAD)" == "$h" && "$(remote_head "$r" stage)" == "$before" ]]
r="$(new_repo diverged dev)"; echo local >"$r/local"; commit "$r" local; h="$(git -C "$r" rev-parse HEAD)"; advance "$r" "$tmp/diverged-peer" dev; before="$(remote_head "$r" dev)"; if out="$(cd "$r" && run --target dev 2>&1)"; then exit 1; fi; [[ "$out" == *'ahead=1'* && "$out" == *'behind=1'* ]]; [[ "$(git -C "$r" rev-parse HEAD)" == "$h" && "$(remote_head "$r" dev)" == "$before" ]]
printf 'target-branch-sync fail-closed tests passed\n'
