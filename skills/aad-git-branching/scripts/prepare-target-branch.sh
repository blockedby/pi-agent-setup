#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'usage: %s [--base <branch>]\n' "${0##*/}" >&2
}

base_branch="main"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --base)
      [[ $# -ge 2 ]] || {
        usage
        exit 1
      }
      base_branch="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

branch_name="$(git branch --show-current)"
[[ -n "$branch_name" ]] || {
  printf 'target-branch-prepare requires a checked-out branch\n' >&2
  exit 1
}

[[ "$branch_name" != "$base_branch" ]] || {
  printf 'target-branch-prepare must run from a feature branch, not %s\n' "$base_branch" >&2
  exit 1
}

state_file="$(git rev-parse --git-path aad-target-branch-prepare.state)"
rebase_merge_dir="$(git rev-parse --git-path rebase-merge)"
rebase_apply_dir="$(git rev-parse --git-path rebase-apply)"
target_ref="origin/$base_branch"
conflict_seen="false"

if [[ -f "$state_file" ]]; then
  conflict_seen="true"
fi

if [[ -d "$rebase_merge_dir" || -d "$rebase_apply_dir" ]]; then
  printf 'branch=%s\n' "$branch_name"
  printf 'base_branch=%s\n' "$base_branch"
  printf 'target_ref=%s\n' "$target_ref"
  printf 'rebase_status=conflicts_pending\n'
  printf 'conflict_seen=true\n'
  printf 'content_changed=unknown\n'
  printf 'rerun_required=true\n'
  printf 'rerun_reason=resolve-rebase-first\n'
  exit 2
fi

git fetch origin "$base_branch" >/dev/null

previous_head="$(git rev-parse HEAD)"

if git rebase "$target_ref" >/dev/null; then
  current_head="$(git rev-parse HEAD)"
  if [[ "$previous_head" == "$current_head" ]]; then
    rebase_status="up_to_date"
  else
    rebase_status="rebased"
  fi

  content_changed="false"
  if [[ "$previous_head" != "$current_head" ]] && git rev-parse -q --verify ORIG_HEAD >/dev/null 2>&1; then
    if ! git diff --quiet ORIG_HEAD..HEAD; then
      content_changed="true"
    fi
  fi

  rerun_required="false"
  rerun_reason="metadata-only-or-noop"
  if [[ "$conflict_seen" == "true" ]]; then
    rerun_required="true"
    rerun_reason="conflicts-resolved-during-rebase"
  elif [[ "$content_changed" == "true" ]]; then
    rerun_required="true"
    rerun_reason="rebased-branch-content-changed"
  fi

  rm -f "$state_file"

  printf 'branch=%s\n' "$branch_name"
  printf 'base_branch=%s\n' "$base_branch"
  printf 'target_ref=%s\n' "$target_ref"
  printf 'previous_head=%s\n' "$previous_head"
  printf 'current_head=%s\n' "$current_head"
  printf 'rebase_status=%s\n' "$rebase_status"
  printf 'conflict_seen=%s\n' "$conflict_seen"
  printf 'content_changed=%s\n' "$content_changed"
  printf 'rerun_required=%s\n' "$rerun_required"
  printf 'rerun_reason=%s\n' "$rerun_reason"
else
  printf 'conflict_seen=true\n' > "$state_file"
  printf 'branch=%s\n' "$branch_name"
  printf 'base_branch=%s\n' "$base_branch"
  printf 'target_ref=%s\n' "$target_ref"
  printf 'previous_head=%s\n' "$previous_head"
  printf 'rebase_status=conflicts_pending\n'
  printf 'conflict_seen=true\n'
  printf 'content_changed=unknown\n'
  printf 'rerun_required=true\n'
  printf 'rerun_reason=resolve-rebase-and-rerun\n'
  exit 2
fi
