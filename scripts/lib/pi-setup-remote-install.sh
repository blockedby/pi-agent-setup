#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$repo_root/scripts/lib/setup-common.sh"
source "$repo_root/scripts/lib/setup-remote-transport.sh"
TARGET_HOST="${TARGET_HOST:-}"
REMOTE_USER_HOME="${REMOTE_USER_HOME:-}"
PI_VERSION="${PI_VERSION:-latest}"
CODEX_VERSION="${CODEX_VERSION:-latest}"
PI_SETTINGS_FILE="${PI_SETTINGS_FILE:-settings/pi-settings.example.json}"
TMP_DIR="/tmp/pi-agent-setup.$$"
settings_path="$repo_root/$PI_SETTINGS_FILE"

pi_setup_require_value TARGET_HOST "$TARGET_HOST"
pi_setup_require_settings_file "$repo_root" "$PI_SETTINGS_FILE"
trap 'pi_setup_cleanup_remote_dir "$TARGET_HOST" "$TMP_DIR"' EXIT
pi_setup_prepare_remote_dir "$TARGET_HOST" "$TMP_DIR" agents extensions settings skills scripts/lib
pi_setup_stage_remote "$TARGET_HOST" "$repo_root/APPEND_SYSTEM.md" "$TMP_DIR/APPEND_SYSTEM.md"
for file in runtime-paths.sh setup-common.sh setup-deployment.sh config-json.py remote-install-payload.sh; do
  pi_setup_stage_remote "$TARGET_HOST" "$repo_root/scripts/lib/$file" "$TMP_DIR/scripts/lib/$file"
done
pi_setup_stage_remote "$TARGET_HOST" "$repo_root/agents/" "$TMP_DIR/agents/"
pi_setup_stage_remote "$TARGET_HOST" "$repo_root/extensions/" "$TMP_DIR/extensions/"
pi_setup_stage_remote "$TARGET_HOST" "$settings_path" "$TMP_DIR/settings/settings.json"
pi_setup_stage_remote "$TARGET_HOST" "$repo_root/settings/pi-subagents.config.json" "$TMP_DIR/settings/pi-subagents.config.json"
pi_setup_stage_remote "$TARGET_HOST" "$repo_root/skills/" "$TMP_DIR/skills/"
ssh "$TARGET_HOST" bash "$TMP_DIR/scripts/lib/remote-install-payload.sh" "$REMOTE_USER_HOME" "$PI_VERSION" "$CODEX_VERSION" "$TMP_DIR"
