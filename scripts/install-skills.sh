#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/local-assets.sh
source "$repo_root/scripts/lib/local-assets.sh"

set_name=""
agent_dir="${PI_AGENT_DIR:-$HOME/.pi/agent}"

usage() {
  echo "usage: scripts/install-skills.sh --set <general|aad|all> [--agent-dir <path>]" >&2
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --set)
      [ "$#" -ge 2 ] || { usage; exit 2; }
      [ -z "$set_name" ] || { echo "--set may be specified only once" >&2; exit 2; }
      set_name="$2"
      shift 2
      ;;
    --agent-dir)
      [ "$#" -ge 2 ] || { usage; exit 2; }
      agent_dir="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2
      ;;
  esac
done

# Set validation deliberately precedes target checks and submodule mutation.
pi_setup_require_skill_set "$set_name"
command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 1; }
pi_setup_validate_skill_target "$repo_root" "$agent_dir"
pi_setup_initialize_skill_sources "$repo_root" "$set_name"
pi_setup_validate_skills "$repo_root" "$set_name"
installed_count="$(pi_setup_install_skills "$repo_root" "$agent_dir" "$set_name")"
echo "Installed $installed_count skills from set=$set_name into $agent_dir/skills."
