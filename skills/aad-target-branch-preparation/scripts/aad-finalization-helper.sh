#!/usr/bin/env bash
# Resolve bundled AAD finalization helpers from this installed skill directory.
set -euo pipefail
usage() { printf 'usage: %s <root-main-sync|target-branch-prepare> [arguments...]\n' "${0##*/}" >&2; }
command_name="${1:-}"
[[ -n "$command_name" ]] || { usage; exit 1; }
shift
bundled_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# This override exists only for hermetic tests that copy/fixture the scripts.
# Normal workflow invocation must use the bundled installed-skill directory.
scripts_dir="${AAD_TARGET_BRANCH_PREPARATION_SCRIPTS_DIR:-$bundled_dir}"
case "$command_name" in
  root-main-sync) target="$scripts_dir/root-main-sync.sh" ;;
  target-branch-prepare) target="$scripts_dir/target-branch-prepare.sh" ;;
  *) usage; exit 1 ;;
esac
[[ -f "$target" ]] || { printf 'AAD finalization helper missing: %s\n' "$target" >&2; exit 1; }
exec bash "$target" "$@"
