#!/usr/bin/env bash
set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

bad_paths=$(git ls-files | grep -E '(^|/)(auth\.json|sessions/|secrets/|state/|id_rsa|id_ed25519|.*\.pem|.*\.key|.*\.PLAINTEXT\.md)$' || true)
if [ -n "$bad_paths" ]; then
  printf 'Refusing tracked secret/runtime paths:\n%s\n' "$bad_paths" >&2
  exit 1
fi

# Lightweight token-pattern scan. Keep this conservative to avoid printing matched secrets.
if git grep -InE '(sk-[A-Za-z0-9_-]{20,}|gh[pousr]_[A-Za-z0-9_]{20,}|BEGIN (OPENSSH|RSA|EC|DSA) PRIVATE KEY|refresh_token|access_token|client_secret)' -- . ':!scripts/secrets-check.sh' >/tmp/pi-agent-setup-secret-hits.$$; then
  cut -d: -f1-2 /tmp/pi-agent-setup-secret-hits.$$ | sort -u >&2
  rm -f /tmp/pi-agent-setup-secret-hits.$$
  echo 'Potential secret patterns found; inspect before committing.' >&2
  exit 1
fi
rm -f /tmp/pi-agent-setup-secret-hits.$$
echo 'secret check ok'
