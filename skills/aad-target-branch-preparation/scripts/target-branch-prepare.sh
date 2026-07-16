#!/usr/bin/env bash
# Fail-closed feature-branch preparation. It never pushes or cleans up.
set -euo pipefail
usage() { printf 'usage: %s [--target <branch>] [--remote <remote>] [--base <branch>]\n' "${0##*/}" >&2; }
target_branch=""
remote="origin"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target|--base) [[ $# -ge 2 ]] || { usage; exit 1; }; target_branch="$2"; shift 2 ;;
    --remote) [[ $# -ge 2 ]] || { usage; exit 1; }; remote="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done
branch_name="$(git branch --show-current)"
[[ -n "$branch_name" ]] || { printf 'target-branch-prepare requires a checked-out feature branch\n' >&2; exit 1; }
infer_target() {
  local configured candidate subject
  configured="$(git config --get "branch.$branch_name.aadTarget" || true)"
  if [[ -n "$configured" ]]; then printf '%s\n' "$configured"; return 0; fi
  subject="$(git reflog show --format=%gs -n 30 "$branch_name" | sed -nE 's/^branch: Created from (refs\/heads\/)?([^ ]+)$/\2/p' | head -n1)"
  [[ -n "$subject" && "$subject" != "$branch_name" ]] || return 1
  # A reflog origin is usable only when the local branch/ref still resolves.
  git rev-parse --verify --quiet "refs/heads/$subject" >/dev/null || return 1
  printf '%s\n' "$subject"
}
if [[ -z "$target_branch" ]]; then
  target_branch="$(infer_target)" || { printf 'cannot infer target branch; pass --target <branch> or record branch.%s.aadTarget\n' "$branch_name" >&2; exit 1; }
fi
[[ "$branch_name" != "$target_branch" ]] || { printf 'target-branch-prepare requires a feature branch distinct from target %s\n' "$target_branch" >&2; exit 1; }
git remote get-url "$remote" >/dev/null 2>&1 || { printf 'remote not found: %s\n' "$remote" >&2; exit 1; }
target_ref="$remote/$target_branch"
state_file="$(git rev-parse --git-path aad-target-branch-prepare.state)"
rebase_merge_dir="$(git rev-parse --git-path rebase-merge)"
rebase_apply_dir="$(git rev-parse --git-path rebase-apply)"
conflict_seen="false"; [[ -f "$state_file" ]] && conflict_seen="true"
print_result() { printf 'branch=%s\ntarget_branch=%s\ntarget_ref=%s\nprevious_head=%s\nprevious_tree=%s\ncurrent_head=%s\ncurrent_tree=%s\nrebase_status=%s\nconflict_seen=%s\ncontent_changed=%s\nrerun_required=%s\nrerun_reason=%s\n' "$branch_name" "$target_branch" "$target_ref" "${previous_head:-unknown}" "${previous_tree:-unknown}" "${current_head:-unknown}" "${current_tree:-unknown}" "$rebase_status" "$conflict_seen" "$content_changed" "$rerun_required" "$rerun_reason"; }
if [[ -d "$rebase_merge_dir" || -d "$rebase_apply_dir" ]]; then rebase_status="conflicts_pending"; content_changed="unknown"; rerun_required="true"; rerun_reason="resolve-rebase-first"; print_result; exit 2; fi
git fetch "$remote" "$target_branch" >/dev/null
previous_head="$(git rev-parse HEAD)"; previous_tree="$(git rev-parse HEAD^{tree})"
if git rebase "$target_ref" >/dev/null; then
  current_head="$(git rev-parse HEAD)"; current_tree="$(git rev-parse HEAD^{tree})"
  [[ "$previous_head" == "$current_head" ]] && rebase_status="up_to_date" || rebase_status="rebased"
  [[ "$previous_tree" == "$current_tree" ]] && content_changed="false" || content_changed="true"
  rerun_required="false"; rerun_reason="metadata-only-or-noop"
  if [[ "$conflict_seen" == "true" ]]; then rerun_required="true"; rerun_reason="conflicts-resolved-during-rebase"; elif [[ "$content_changed" == "true" ]]; then rerun_required="true"; rerun_reason="rebased-branch-content-changed"; fi
  rm -f "$state_file"; print_result
else
  printf 'conflict_seen=true\n' > "$state_file"; rebase_status="conflicts_pending"; content_changed="unknown"; rerun_required="true"; rerun_reason="resolve-rebase-and-rerun"; print_result; exit 2
fi
