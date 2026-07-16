#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SCRIPT="$ROOT/scripts/aad-finalization-helper.sh"
run_helper() { bash "$SCRIPT" root-main-sync "$@"; }
# The explicit override is supported only to make this hermetic fixture testable.
AAD_TARGET_BRANCH_PREPARATION_SCRIPTS_DIR="$ROOT/scripts" run_helper --help >/dev/null
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
commit() { git -C "$1" add .; git -C "$1" -c user.name=test -c user.email=test@example.invalid commit -m "$2" >/dev/null; }
new_repo() {
  local name="$1"; local origin="$tmp/$name.git"; local root="$tmp/$name-root"
  git init --bare "$origin" >/dev/null
  git clone "$origin" "$root" >/dev/null 2>&1
  git -C "$root" checkout -b main >/dev/null
  echo base >"$root/base"; commit "$root" base; git -C "$root" push -u origin main >/dev/null
  printf '%s\n' "$root"
}
advance_remote() { local root="$1"; local peer="$2"; git clone "$(git -C "$root" remote get-url origin)" "$peer" >/dev/null 2>&1; git -C "$peer" checkout main >/dev/null; echo remote >"$peer/remote"; commit "$peer" remote; git -C "$peer" push origin main >/dev/null; }
assert_no_remote_mutation() { [[ "$(git -C "$1" ls-remote origin refs/heads/main | awk '{print $1}')" == "$2" ]]; }
# Equal state: allowed no-op, no cleanup requested.
r="$(new_repo equal)"; before="$(git -C "$r" ls-remote origin refs/heads/main | awk '{print $1}')"; out="$(cd "$r" && run_helper)"; [[ "$out" == *'sync_status=up_to_date'* ]]; assert_no_remote_mutation "$r" "$before"
# Behind-only state: only fast-forward, no publishing.
r="$(new_repo behind)"; advance_remote "$r" "$tmp/behind-peer"; before="$(git -C "$r" ls-remote origin refs/heads/main | awk '{print $1}')"; out="$(cd "$r" && run_helper)"; [[ "$out" == *'sync_status=fast_forwarded'* ]]; [[ -f "$r/remote" ]]; [[ "$(git -C "$r" rev-parse HEAD)" == "$before" ]]; assert_no_remote_mutation "$r" "$before"
# Dirty state: reject before cleanup and leave requested feature worktree intact.
r="$(new_repo dirty)"; git -C "$r" worktree add -b feature/dirty "$tmp/dirty-feature" >/dev/null; echo feature >"$tmp/dirty-feature/f"; commit "$tmp/dirty-feature" feature; echo dirty >>"$r/base"; before="$(git -C "$r" ls-remote origin refs/heads/main | awk '{print $1}')"; if out="$(cd "$r" && run_helper --delete-worktree "$tmp/dirty-feature" --delete-branch feature/dirty 2>&1)"; then exit 1; fi; [[ "$out" == *'sync_status=rejected'* ]]; [[ -d "$tmp/dirty-feature" ]]; assert_no_remote_mutation "$r" "$before"
# Ahead state: reject and do not publish local main.
r="$(new_repo ahead)"; echo local >"$r/local"; commit "$r" local; local_head="$(git -C "$r" rev-parse HEAD)"; before="$(git -C "$r" ls-remote origin refs/heads/main | awk '{print $1}')"; if out="$(cd "$r" && run_helper 2>&1)"; then exit 1; fi; [[ "$out" == *'ahead=1'* && "$out" == *'sync_status=rejected'* ]]; [[ "$(git -C "$r" rev-parse HEAD)" == "$local_head" ]]; assert_no_remote_mutation "$r" "$before"
# Diverged state: reject with neither rebase nor push.
r="$(new_repo diverged)"; echo local >"$r/local"; commit "$r" local; local_head="$(git -C "$r" rev-parse HEAD)"; advance_remote "$r" "$tmp/diverged-peer"; before="$(git -C "$r" ls-remote origin refs/heads/main | awk '{print $1}')"; if out="$(cd "$r" && run_helper 2>&1)"; then exit 1; fi; [[ "$out" == *'ahead=1'* && "$out" == *'behind=1'* ]]; [[ "$(git -C "$r" rev-parse HEAD)" == "$local_head" ]]; assert_no_remote_mutation "$r" "$before"
printf 'root-main-sync fail-closed tests passed\n'
