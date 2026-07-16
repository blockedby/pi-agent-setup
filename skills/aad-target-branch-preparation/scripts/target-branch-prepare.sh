#!/usr/bin/env bash
# Deterministic feature-branch preparation helper. It never pushes or cleans up.
set -euo pipefail
usage() { printf 'usage: %s [--base <branch>]\n' "${0##*/}" >&2; }
base_branch="main"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --base) [[ $# -ge 2 ]] || { usage; exit 1; }; base_branch="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done
branch_name="$(git branch --show-current)"
[[ -n "$branch_name" && "$branch_name" != "$base_branch" ]] || { printf 'target-branch-prepare requires a checked-out feature branch\n' >&2; exit 1; }
target_ref="origin/$base_branch"
state_file="$(git rev-parse --git-path aad-target-branch-prepare.state)"
rebase_merge_dir="$(git rev-parse --git-path rebase-merge)"
rebase_apply_dir="$(git rev-parse --git-path rebase-apply)"
conflict_seen="false"
[[ -f "$state_file" ]] && conflict_seen="true"
print_result() {
  printf 'branch=%s\nbase_branch=%s\ntarget_ref=%s\nprevious_head=%s\nprevious_tree=%s\ncurrent_head=%s\ncurrent_tree=%s\nrebase_status=%s\nconflict_seen=%s\ncontent_changed=%s\nrerun_required=%s\nrerun_reason=%s\n' \
    "$branch_name" "$base_branch" "$target_ref" "${previous_head:-unknown}" "${previous_tree:-unknown}" "${current_head:-unknown}" "${current_tree:-unknown}" "$rebase_status" "$conflict_seen" "$content_changed" "$rerun_required" "$rerun_reason"
}
if [[ -d "$rebase_merge_dir" || -d "$rebase_apply_dir" ]]; then
  rebase_status="conflicts_pending"; content_changed="unknown"; rerun_required="true"; rerun_reason="resolve-rebase-first"; print_result; exit 2
fi
git fetch origin "$base_branch" >/dev/null
previous_head="$(git rev-parse HEAD)"
previous_tree="$(git rev-parse HEAD^{tree})"
if git rebase "$target_ref" >/dev/null; then
  current_head="$(git rev-parse HEAD)"
  current_tree="$(git rev-parse HEAD^{tree})"
  if [[ "$previous_head" == "$current_head" ]]; then rebase_status="up_to_date"; else rebase_status="rebased"; fi
  if [[ "$previous_tree" == "$current_tree" ]]; then content_changed="false"; else content_changed="true"; fi
  rerun_required="false"; rerun_reason="metadata-only-or-noop"
  if [[ "$conflict_seen" == "true" ]]; then rerun_required="true"; rerun_reason="conflicts-resolved-during-rebase"
  elif [[ "$content_changed" == "true" ]]; then rerun_required="true"; rerun_reason="rebased-branch-content-changed"; fi
  rm -f "$state_file"
  print_result
else
  printf 'conflict_seen=true\n' > "$state_file"
  rebase_status="conflicts_pending"; content_changed="unknown"; rerun_required="true"; rerun_reason="resolve-rebase-and-rerun"; print_result; exit 2
fi
