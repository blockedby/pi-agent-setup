#!/usr/bin/env bash
set -euo pipefail

if [ "${CONFIRM_COPY_PI_AUTH:-}" != "1" ]; then
  echo 'Refusing to copy auth. Re-run with CONFIRM_COPY_PI_AUTH=1 when explicitly approved.' >&2
  exit 1
fi

TARGET_HOST="${TARGET_HOST:-nl-2-nvme}"
LOCAL_AUTH="${LOCAL_AUTH:-$HOME/.pi/agent/auth.json}"
REMOTE_AUTH="${REMOTE_AUTH:-/root/.pi/agent/auth.json}"

if [ ! -f "$LOCAL_AUTH" ]; then
  echo "Local auth file not found: $LOCAL_AUTH" >&2
  exit 1
fi

ssh "$TARGET_HOST" 'mkdir -p /root/.pi/agent && chmod 700 /root/.pi /root/.pi/agent'
rsync -a --chmod=F600 "$LOCAL_AUTH" "$TARGET_HOST:$REMOTE_AUTH"
ssh "$TARGET_HOST" "chmod 600 '$REMOTE_AUTH' && chown root:root '$REMOTE_AUTH'"
echo 'Pi auth copied without printing contents.'
