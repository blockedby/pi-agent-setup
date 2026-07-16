#!/usr/bin/env bash
# Fail-closed target-checkout synchronization for AAD finalization.
set -euo pipefail
usage() { printf 'usage: %s [--target <branch>] [--remote <remote>] [--base <branch>] [--delete-worktree <path>] [--delete-branch <branch>]\n' "${0##*/}" >&2; }
target_branch=""; remote="origin"; delete_worktree=""; delete_branch=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target|--base) [[ $# -ge 2 ]] || { usage; exit 1; }; target_branch="$2"; shift 2 ;;
    --remote) [[ $# -ge 2 ]] || { usage; exit 1; }; remote="$2"; shift 2 ;;
    --delete-worktree) [[ $# -ge 2 ]] || { usage; exit 1; }; delete_worktree="$2"; shift 2 ;;
    --delete-branch) [[ $# -ge 2 ]] || { usage; exit 1; }; delete_branch="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) usage; exit 1 ;;
  esac
done
repo_root="$(realpath -m "$(git rev-parse --show-toplevel)")"
current_branch="$(git branch --show-current)"
[[ -n "$target_branch" ]] || target_branch="$current_branch"
[[ -n "$target_branch" ]] || { printf 'cannot infer target branch from detached checkout; pass --target\n' >&2; exit 1; }
primary_target_worktree() { local current=""; while IFS= read -r line || [[ -n "$line" ]]; do if [[ "$line" == worktree\ * ]]; then current="${line#worktree }"; elif [[ "$line" == "branch refs/heads/$target_branch" ]]; then printf '%s\n' "$current"; return 0; fi; done < <(git worktree list --porcelain); return 1; }
primary_root="$(realpath -m "$(primary_target_worktree)")" || { printf 'cannot locate target checkout for %s\n' "$target_branch" >&2; exit 1; }
clean=false; ahead=unknown; behind=unknown; sync_status=rejected; cleanup_worktree=not_requested; cleanup_branch=not_requested
summary() { printf 'target_root=%s\ncurrent_branch=%s\ntarget_branch=%s\nremote=%s\nclean=%s\nahead=%s\nbehind=%s\nsync_status=%s\ncleanup_worktree=%s\ncleanup_branch=%s\n' "$primary_root" "$current_branch" "$target_branch" "$remote" "$clean" "$ahead" "$behind" "$sync_status" "$cleanup_worktree" "$cleanup_branch"; }
[[ "$repo_root" == "$primary_root" ]] || { printf 'target-branch-sync must run from target checkout %s (current: %s)\n' "$primary_root" "$repo_root" >&2; summary; exit 1; }
[[ "$current_branch" == "$target_branch" ]] || { printf 'target-branch-sync must run on %s (current: %s)\n' "$target_branch" "$current_branch" >&2; summary; exit 1; }
git remote get-url "$remote" >/dev/null 2>&1 || { printf 'remote not found: %s\n' "$remote" >&2; summary; exit 1; }
[[ -z "$(git status --porcelain --untracked-files=all)" ]] && clean=true
[[ "$clean" == true ]] || { printf 'target-branch-sync rejects dirty target checkout\n' >&2; summary; exit 1; }
git fetch "$remote" "$target_branch" >/dev/null
read -r ahead behind < <(git rev-list --left-right --count "HEAD...$remote/$target_branch")
if [[ "$ahead" -gt 0 ]]; then printf 'target-branch-sync rejects ahead or diverged target checkout (ahead=%s behind=%s)\n' "$ahead" "$behind" >&2; summary; exit 1; fi
if [[ "$behind" -gt 0 ]]; then git merge --ff-only "$remote/$target_branch" >/dev/null; sync_status=fast_forwarded; else sync_status=up_to_date; fi
if [[ -n "$delete_worktree" ]]; then delete_worktree="$(realpath -m "$delete_worktree")"; [[ "$delete_worktree" != "$primary_root" ]] || { printf 'refusing to remove target checkout\n' >&2; summary; exit 1; }; if git worktree list --porcelain | grep -Fqx "worktree $delete_worktree"; then git worktree remove "$delete_worktree" >/dev/null; cleanup_worktree=removed; else cleanup_worktree=missing; fi; fi
if [[ -n "$delete_branch" ]]; then [[ "$delete_branch" != "$target_branch" ]] || { printf 'refusing to delete target branch\n' >&2; summary; exit 1; }; if git show-ref --verify --quiet "refs/heads/$delete_branch"; then git branch -D "$delete_branch" >/dev/null; cleanup_branch=deleted; else cleanup_branch=missing; fi; fi
summary
