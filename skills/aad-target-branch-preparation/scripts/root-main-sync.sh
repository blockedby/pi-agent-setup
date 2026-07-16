#!/usr/bin/env bash
# Fail-closed primary-main post-merge synchronization for AAD finalization.
set -euo pipefail

usage() {
  printf 'usage: %s [--base <branch>] [--delete-worktree <path>] [--delete-branch <branch>]\n' "${0##*/}" >&2
}

primary_main_worktree() {
  local current=""
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == worktree\ * ]]; then
      current="${line#worktree }"
    elif [[ "$line" == "branch refs/heads/$base_branch" ]]; then
      printf '%s\n' "$current"
      return 0
    fi
  done < <(git worktree list --porcelain)
  return 1
}

base_branch="main"
delete_worktree=""
delete_branch=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --base) [[ $# -ge 2 ]] || { usage; exit 1; }; base_branch="$2"; shift 2 ;;
    --delete-worktree) [[ $# -ge 2 ]] || { usage; exit 1; }; delete_worktree="$2"; shift 2 ;;
    --delete-branch) [[ $# -ge 2 ]] || { usage; exit 1; }; delete_branch="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done

repo_root="$(realpath -m "$(git rev-parse --show-toplevel)")"
primary_root="$(realpath -m "$(primary_main_worktree)")" || {
  printf 'cannot locate primary worktree for %s\n' "$base_branch" >&2
  exit 1
}
current_branch="$(git branch --show-current)"
summary() {
  printf 'primary_root=%s\ncurrent_branch=%s\nclean=%s\nahead=%s\nbehind=%s\nsync_status=%s\ncleanup_worktree=%s\ncleanup_branch=%s\n' \
    "$primary_root" "$current_branch" "$clean" "$ahead" "$behind" "$sync_status" "$cleanup_worktree" "$cleanup_branch"
}

clean="false"
ahead="unknown"
behind="unknown"
sync_status="rejected"
cleanup_worktree="not_requested"
cleanup_branch="not_requested"

[[ "$repo_root" == "$primary_root" ]] || { printf 'root-main-sync must run from primary checkout %s (current: %s)\n' "$primary_root" "$repo_root" >&2; summary; exit 1; }
[[ "$current_branch" == "$base_branch" ]] || { printf 'root-main-sync must run on %s (current: %s)\n' "$base_branch" "$current_branch" >&2; summary; exit 1; }
if [[ -z "$(git status --porcelain --untracked-files=all)" ]]; then clean="true"; fi
[[ "$clean" == "true" ]] || { printf 'root-main-sync rejects dirty primary checkout\n' >&2; summary; exit 1; }

git fetch origin "$base_branch" >/dev/null
read -r ahead behind < <(git rev-list --left-right --count "HEAD...origin/$base_branch")
if [[ "$ahead" -gt 0 ]]; then
  printf 'root-main-sync rejects ahead or diverged primary checkout (ahead=%s behind=%s)\n' "$ahead" "$behind" >&2
  summary
  exit 1
fi

if [[ "$behind" -gt 0 ]]; then
  git merge --ff-only "origin/$base_branch" >/dev/null
  sync_status="fast_forwarded"
else
  sync_status="up_to_date"
fi

if [[ -n "$delete_worktree" ]]; then
  delete_worktree="$(realpath -m "$delete_worktree")"
  [[ "$delete_worktree" != "$primary_root" ]] || { printf 'refusing to remove primary worktree\n' >&2; summary; exit 1; }
  if git worktree list --porcelain | grep -Fqx "worktree $delete_worktree"; then
    git worktree remove "$delete_worktree" >/dev/null
    cleanup_worktree="removed"
  else cleanup_worktree="missing"; fi
fi
if [[ -n "$delete_branch" ]]; then
  [[ "$delete_branch" != "$base_branch" ]] || { printf 'refusing to delete base branch\n' >&2; summary; exit 1; }
  if git show-ref --verify --quiet "refs/heads/$delete_branch"; then
    git branch -D "$delete_branch" >/dev/null
    cleanup_branch="deleted"
  else cleanup_branch="missing"; fi
fi
summary
