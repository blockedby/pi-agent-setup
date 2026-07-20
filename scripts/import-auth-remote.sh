#!/usr/bin/env bash
# Compatibility wrapper. Prefer: scripts/pi-setup remote import-auth --host <host> --confirm
set -euo pipefail
if [ "${CONFIRM_COPY_PI_AUTH:-}" != "1" ]; then
  echo 'Refusing to copy auth. Re-run with CONFIRM_COPY_PI_AUTH=1 when explicitly approved.' >&2
  exit 1
fi
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/pi-setup" remote import-auth --confirm "$@"
