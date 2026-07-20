#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
source "$repo_root/scripts/lib/setup-common.sh"
source "$repo_root/scripts/lib/setup-remote-transport.sh"
[ "${CONFIRM_COPY_PI_AUTH:-}" = 1 ] || { echo 'Refusing to copy auth. Re-run with CONFIRM_COPY_PI_AUTH=1 when explicitly approved.' >&2; exit 1; }
TARGET_HOST="${TARGET_HOST:-}"
REMOTE_USER_HOME="${REMOTE_USER_HOME:-}"
LOCAL_AUTH="${LOCAL_AUTH:-$HOME/.pi/agent/auth.json}"
REMOTE_AUTH="${REMOTE_AUTH:-}"
TMP_DIR="/tmp/pi-agent-setup-auth.$$"

pi_setup_require_value TARGET_HOST "$TARGET_HOST"
[ -f "$LOCAL_AUTH" ] || { echo "Local auth file not found: $LOCAL_AUTH" >&2; exit 1; }
remote_auth_tmp="$(mktemp)"
cleanup() { rm -f "$remote_auth_tmp"; pi_setup_cleanup_remote_dir "$TARGET_HOST" "$TMP_DIR"; }
trap cleanup EXIT
pi_setup_prepare_remote_dir "$TARGET_HOST" "$TMP_DIR" scripts/lib
for file in setup-common.sh remote-auth-path-payload.sh; do
  pi_setup_stage_remote "$TARGET_HOST" "$repo_root/scripts/lib/$file" "$TMP_DIR/scripts/lib/$file"
done
ssh "$TARGET_HOST" bash "$TMP_DIR/scripts/lib/remote-auth-path-payload.sh" "$REMOTE_USER_HOME" "$REMOTE_AUTH" "$TMP_DIR" >"$remote_auth_tmp"
REMOTE_AUTH_PATH="$(tail -n 1 "$remote_auth_tmp")"
rsync -a --chmod=F600 "$LOCAL_AUTH" "$TARGET_HOST:$REMOTE_AUTH_PATH"
ssh "$TARGET_HOST" "chmod 600 '$REMOTE_AUTH_PATH'"
printf '%s\n' 'Pi auth copied without printing contents.'
