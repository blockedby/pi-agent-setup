#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$repo_root/scripts/lib/setup-common.sh"
source "$repo_root/scripts/lib/setup-remote-transport.sh"
TARGET_HOST="${TARGET_HOST:-}"
REMOTE_USER_HOME="${REMOTE_USER_HOME:-}"
TMP_DIR="/tmp/pi-agent-setup-verify.$$"

pi_setup_require_value TARGET_HOST "$TARGET_HOST"
trap 'pi_setup_cleanup_remote_dir "$TARGET_HOST" "$TMP_DIR"' EXIT
pi_setup_prepare_remote_dir "$TARGET_HOST" "$TMP_DIR" scripts/lib
for file in setup-common.sh setup-assets.sh setup-verification.sh config-json.py remote-verify-payload.sh; do
  pi_setup_stage_remote "$TARGET_HOST" "$repo_root/scripts/lib/$file" "$TMP_DIR/scripts/lib/$file"
done
ssh "$TARGET_HOST" bash "$TMP_DIR/scripts/lib/remote-verify-payload.sh" "$REMOTE_USER_HOME" "$TMP_DIR"
