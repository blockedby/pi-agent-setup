#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "$HERE/root-main-sync.sh"
bash "$HERE/target-branch-prepare.sh"
printf 'aad target-branch helper tests passed\n'
