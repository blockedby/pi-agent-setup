#!/usr/bin/env bash
set -euo pipefail

if [ "${CONFIRM_COPY_PI_AUTH:-}" != "1" ]; then
  echo 'Refusing to copy auth. Re-run with CONFIRM_COPY_PI_AUTH=1 when explicitly approved.' >&2
  exit 1
fi

TARGET_HOST="${TARGET_HOST:-}"
REMOTE_USER_HOME="${REMOTE_USER_HOME:-}"
LOCAL_AUTH="${LOCAL_AUTH:-$HOME/.pi/agent/auth.json}"
REMOTE_AUTH="${REMOTE_AUTH:-}"

if [ -z "$TARGET_HOST" ]; then
  echo "TARGET_HOST is required, for example: TARGET_HOST=<host> $0" >&2
  exit 2
fi
if [ ! -f "$LOCAL_AUTH" ]; then
  echo "Local auth file not found: $LOCAL_AUTH" >&2
  exit 1
fi

remote_auth_tmp="$(mktemp)"
trap 'rm -f "$remote_auth_tmp"' EXIT
ssh "$TARGET_HOST" bash -s -- "$REMOTE_USER_HOME" "$REMOTE_AUTH" >"$remote_auth_tmp" <<'REMOTE'
set -euo pipefail
REQUESTED_REMOTE_USER_HOME="$1"
REQUESTED_REMOTE_AUTH="$2"

if [ -n "$REQUESTED_REMOTE_USER_HOME" ]; then
  if [ -d "$REQUESTED_REMOTE_USER_HOME" ]; then
    REMOTE_USER_HOME="$REQUESTED_REMOTE_USER_HOME"
  else
    echo "REMOTE_USER_HOME does not exist on target: $REQUESTED_REMOTE_USER_HOME" >&2
    exit 2
  fi
elif [ -n "${HOME:-}" ] && [ -d "$HOME" ]; then
  REMOTE_USER_HOME="$HOME"
else
  REMOTE_USER_HOME="/root"
fi

if [ -n "$REQUESTED_REMOTE_AUTH" ]; then
  REMOTE_AUTH_PATH="$REQUESTED_REMOTE_AUTH"
else
  REMOTE_AUTH_PATH="$REMOTE_USER_HOME/.pi/agent/auth.json"
fi

REMOTE_AUTH_DIR="$(dirname "$REMOTE_AUTH_PATH")"
mkdir -p "$REMOTE_AUTH_DIR"
chmod 700 "$REMOTE_USER_HOME/.pi" "$REMOTE_USER_HOME/.pi/agent" 2>/dev/null || true
printf '%s\n' "$REMOTE_AUTH_PATH"
REMOTE
REMOTE_AUTH_PATH="$(tail -n 1 "$remote_auth_tmp")"

rsync -a --chmod=F600 "$LOCAL_AUTH" "$TARGET_HOST:$REMOTE_AUTH_PATH"
ssh "$TARGET_HOST" "chmod 600 '$REMOTE_AUTH_PATH'"
echo 'Pi auth copied without printing contents.'
