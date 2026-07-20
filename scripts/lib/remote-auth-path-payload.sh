#!/usr/bin/env bash
set -euo pipefail

REQUESTED_REMOTE_USER_HOME="$1"
REQUESTED_REMOTE_AUTH="$2"
TMP_DIR="$3"
source "$TMP_DIR/scripts/lib/setup-common.sh"
REMOTE_USER_HOME="$(pi_setup_resolve_home "$REQUESTED_REMOTE_USER_HOME")"
if [ -n "$REQUESTED_REMOTE_AUTH" ]; then
  REMOTE_AUTH_PATH="$REQUESTED_REMOTE_AUTH"
else
  REMOTE_AUTH_PATH="$REMOTE_USER_HOME/.pi/agent/auth.json"
fi
mkdir -p "$(dirname "$REMOTE_AUTH_PATH")"
chmod 700 "$REMOTE_USER_HOME/.pi" "$REMOTE_USER_HOME/.pi/agent" 2>/dev/null || true
printf '%s\n' "$REMOTE_AUTH_PATH"
