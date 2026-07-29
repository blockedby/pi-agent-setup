#!/usr/bin/env bash
set -euo pipefail

usage() {
  printf 'usage: %s [--base <branch>] [--delete-worktree <path>] [--delete-branch <branch>]\n' "${0##*/}" >&2
}

target_branch_worktree() {
  local target_branch="$1"
  local current=""

  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ "$line" == worktree\ * ]]; then
      current="${line#worktree }"
    elif [[ "$line" == "branch refs/heads/$target_branch" ]]; then
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
    --base)
      [[ $# -ge 2 ]] || {
        usage
        exit 1
      }
      base_branch="$2"
      shift 2
      ;;
    --delete-worktree)
      [[ $# -ge 2 ]] || {
        usage
        exit 1
      }
      delete_worktree="$2"
      shift 2
      ;;
    --delete-branch)
      [[ $# -ge 2 ]] || {
        usage
        exit 1
      }
      delete_branch="$2"
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

repo_root="$(realpath -m "$(git rev-parse --show-toplevel)")"
if ! target_root="$(target_branch_worktree "$base_branch")"; then
  printf 'no worktree has target branch %s checked out\n' "$base_branch" >&2
  exit 1
fi
target_root="$(realpath -m "$target_root")"
current_branch="$(git branch --show-current)"

[[ "$repo_root" == "$target_root" ]] || {
  printf 'sync-target-branch must run from the checkout holding %s at %s (current: %s)\n' \
    "$base_branch" "$target_root" "$repo_root" >&2
  exit 1
}

[[ "$current_branch" == "$base_branch" ]] || {
  printf 'sync-target-branch must run while %s is checked out (current: %s)\n' \
    "$base_branch" "$current_branch" >&2
  exit 1
}

stash_created="false"
stash_restored="false"
stash_label=""
stash_ref=""
sync_status="up_to_date"
cleanup_worktree="not_requested"
cleanup_branch="not_requested"

print_summary() {
  printf 'target_root=%s\n' "$target_root"
  printf 'base_branch=%s\n' "$base_branch"
  printf 'current_branch=%s\n' "$current_branch"
  printf 'stash_created=%s\n' "$stash_created"
  printf 'stash_restored=%s\n' "$stash_restored"
  printf 'stash_label=%s\n' "$stash_label"
  printf 'sync_status=%s\n' "$sync_status"
  printf 'cleanup_worktree=%s\n' "$cleanup_worktree"
  printf 'cleanup_branch=%s\n' "$cleanup_branch"
}

if [[ -n "$(git status --porcelain --untracked-files=all)" ]]; then
  stash_created="true"
  stash_label="git-branching-target-sync:$(date -u +%Y%m%dT%H%M%SZ):$$"
  git stash push --include-untracked -m "$stash_label" >/dev/null
  stash_ref="stash@{0}"
fi

git fetch origin "$base_branch" >/dev/null

read -r ahead behind < <(git rev-list --left-right --count "HEAD...origin/$base_branch")

if [[ "$ahead" -eq 0 && "$behind" -eq 0 ]]; then
  sync_status="up_to_date"
elif [[ "$ahead" -eq 0 && "$behind" -gt 0 ]]; then
  git merge --ff-only "origin/$base_branch" >/dev/null
  sync_status="fast_forwarded"
elif [[ "$ahead" -gt 0 && "$behind" -eq 0 ]]; then
  git push origin "$base_branch" >/dev/null
  sync_status="pushed_local_target"
else
  git rebase "origin/$base_branch" >/dev/null
  git push origin "$base_branch" >/dev/null
  sync_status="rebased_and_pushed"
fi

if [[ "$stash_created" == "true" ]]; then
  if git stash apply "$stash_ref" >/dev/null; then
    git stash drop "$stash_ref" >/dev/null
    stash_restored="true"
  else
    sync_status="stash_restore_conflict"
    print_summary
    exit 2
  fi
fi

if [[ -n "$delete_worktree" ]]; then
  delete_worktree="$(realpath -m "$delete_worktree")"
  if [[ "$delete_worktree" == "$target_root" ]]; then
    printf 'refusing to remove target worktree %s\n' "$delete_worktree" >&2
    exit 1
  fi

  if git worktree list --porcelain | grep -Fq "worktree $delete_worktree"; then
    git worktree remove "$delete_worktree" >/dev/null
    cleanup_worktree="removed"
  else
    cleanup_worktree="missing"
  fi
fi

if [[ -n "$delete_branch" ]]; then
  [[ "$delete_branch" != "$base_branch" ]] || {
    printf 'refusing to delete target branch %s\n' "$delete_branch" >&2
    exit 1
  }

  if git show-ref --verify --quiet "refs/heads/$delete_branch"; then
    git branch -D "$delete_branch" >/dev/null
    cleanup_branch="deleted"
  else
    cleanup_branch="missing"
  fi
fi

print_summary
