#!/usr/bin/env bash
# Compatibility wrapper. Prefer: scripts/pi-setup local install
set -euo pipefail
exec "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/pi-setup" local install "$@"
