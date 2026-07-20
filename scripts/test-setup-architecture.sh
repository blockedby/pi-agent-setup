#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "setup architecture test failed: $*" >&2; exit 1; }

python3 "$repo_root/scripts/test-shell-architecture.py" "$repo_root"
for payload in remote-install-payload.sh remote-verify-payload.sh remote-auth-path-payload.sh; do
  test -x "$repo_root/scripts/lib/$payload" || fail "missing executable remote payload: $payload"
done
grep -Fq 'remote-install-payload.sh' "$repo_root/scripts/lib/pi-setup-remote-install.sh" || fail 'install orchestrator does not stage its payload'
grep -Fq 'remote-verify-payload.sh' "$repo_root/scripts/lib/pi-setup-remote-verify.sh" || fail 'verify orchestrator does not stage its payload'
grep -Fq 'remote-auth-path-payload.sh' "$repo_root/scripts/lib/pi-setup-remote-import-auth.sh" || fail 'auth orchestrator does not stage its payload'
grep -Fq 'setup-deployment.sh' "$repo_root/scripts/lib/pi-setup-local-install.sh" || fail 'local installer does not reuse deployment helper'
grep -Fq 'setup-deployment.sh' "$repo_root/scripts/lib/remote-install-payload.sh" || fail 'remote install payload does not reuse deployment helper'
grep -Fq 'setup-remote-transport.sh' "$repo_root/scripts/lib/pi-setup-remote-install.sh" || fail 'install orchestrator does not use transport helper'
grep -Fq 'setup-verification.sh' "$repo_root/scripts/lib/remote-verify-payload.sh" || fail 'verify payload does not use verification helper'
grep -Fq 'setup-assets.sh' "$repo_root/scripts/lib/pi-setup-remote-verify.sh" || fail 'verify orchestrator does not stage the asset manifest'
grep -Fq 'merge' "$repo_root/scripts/lib/pi-setup-local-install.sh" || fail 'local installer does not select merge skill sync'
grep -Fq 'replace' "$repo_root/scripts/lib/remote-install-payload.sh" || fail 'remote payload does not select replace skill sync'
printf '%s\n' 'setup architecture tests passed'
