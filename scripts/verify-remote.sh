#!/usr/bin/env bash
# Compatibility wrapper. Prefer: scripts/pi-setup remote verify --host <host>
set -euo pipefail
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/pi-setup" remote verify "$@"
