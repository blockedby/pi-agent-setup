#!/usr/bin/env bash
set -euo pipefail
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT
fail() { echo "pi-setup test failed: $*" >&2; exit 1; }
expect_fail() { if "$@" >"$tmp_root/out" 2>&1; then fail "expected failure: $*"; fi; }

# Parser validation happens before network or local installation and errors are stable.
expect_fail "$repo_root/scripts/pi-setup" remote install
expect_fail "$repo_root/scripts/pi-setup" remote verify
expect_fail "$repo_root/scripts/pi-setup" remote import-auth --host example.invalid
expect_fail "$repo_root/scripts/pi-setup" local install --settings missing.json
for option in --host --home --settings --pi-version --codex-version --local-auth --remote-auth; do
  expect_fail "$repo_root/scripts/pi-setup" remote install "$option"
  grep -Fq -- "$option requires a value" "$tmp_root/out" || fail "missing-value error was not normalized: $option"
done

# Legacy wrappers execute the dispatcher with their documented environment inputs.
expect_fail env PI_SETTINGS_FILE=missing.json bash "$repo_root/scripts/update-local.sh"
grep -Fq 'PI_SETTINGS_FILE not found: missing.json' "$tmp_root/out" || fail "local wrapper did not forward environment"
expect_fail env TARGET_HOST=example.invalid PI_SETTINGS_FILE=missing.json bash "$repo_root/scripts/install-remote.sh"
grep -Fq 'PI_SETTINGS_FILE not found: missing.json' "$tmp_root/out" || fail "install wrapper did not forward environment"
expect_fail env -u TARGET_HOST bash "$repo_root/scripts/verify-remote.sh"
grep -Fq 'TARGET_HOST is required' "$tmp_root/out" || fail "verify wrapper did not forward validation"
expect_fail env -u TARGET_HOST CONFIRM_COPY_PI_AUTH=0 bash "$repo_root/scripts/import-auth-remote.sh"
grep -Fq 'Refusing to copy auth' "$tmp_root/out" || fail "auth wrapper did not preserve confirmation-first rejection"

# CLI flags must beat environment variables.
expect_fail env PI_SETTINGS_FILE=settings/pi-settings.example.json "$repo_root/scripts/pi-setup" local install --settings missing.json
grep -Fq 'PI_SETTINGS_FILE not found: missing.json' "$tmp_root/out" || fail "flagged settings did not override environment"

# Home resolution is shared and never consults the caller's real Pi config.
source "$repo_root/scripts/lib/setup-common.sh"
home="$tmp_root/home"; mkdir -p "$home"
[ "$(pi_setup_resolve_home "$home")" = "$home" ] || fail "requested home not resolved"
if pi_setup_resolve_home "$tmp_root/missing" >"$tmp_root/out" 2>&1; then fail "missing home accepted"; fi
HOME="$home"; export HOME
[ "$(pi_setup_resolve_home '')" = "$home" ] || fail "HOME fallback not resolved"
# Each remote operation transfers and sources the same helper, then invokes it.
for remote_script in pi-setup-remote-install.sh pi-setup-remote-verify.sh pi-setup-remote-import-auth.sh; do
  grep -Fq 'setup-common.sh' "$repo_root/scripts/lib/$remote_script" || fail "$remote_script does not transfer shared helper"
  grep -Fq 'pi_setup_resolve_home' "$repo_root/scripts/lib/$remote_script" || fail "$remote_script does not invoke shared home resolution"
done

# MCP merges preserve unrelated servers and are idempotent.
cat > "$tmp_root/mcp-source.json" <<'JSON'
{"mcpServers":{"example":{"command":"npx","args":["example"]}}}
JSON
printf '{"mcpServers":{"keep":{"command":"keep"}}}\n' > "$tmp_root/mcp.json"
python3 "$repo_root/scripts/lib/config-json.py" merge-mcp "$tmp_root/mcp.json" "$tmp_root/mcp-source.json" test
first="$(sha256sum "$tmp_root/mcp.json")"
python3 "$repo_root/scripts/lib/config-json.py" merge-mcp "$tmp_root/mcp.json" "$tmp_root/mcp-source.json" test
second="$(sha256sum "$tmp_root/mcp.json")"
[ "$first" = "$second" ] || fail "MCP mutation is not idempotent"
python3 - "$tmp_root/mcp.json" <<'PY'
import json, sys
assert set(json.load(open(sys.argv[1]))['mcpServers']) == {'keep', 'example'}
PY
printf '{"mcpServers":{"keep":{"command":"keep"}}}\n' > "$tmp_root/chrome-mcp.json"
python3 "$repo_root/scripts/lib/config-json.py" browser-chrome-mcp "$tmp_root/chrome-mcp.json" /opt/chrome-mcp.sh
first="$(sha256sum "$tmp_root/chrome-mcp.json")"
python3 "$repo_root/scripts/lib/config-json.py" browser-chrome-mcp "$tmp_root/chrome-mcp.json" /opt/chrome-mcp.sh
second="$(sha256sum "$tmp_root/chrome-mcp.json")"
[ "$first" = "$second" ] || fail "Browser Chrome MCP mutation is not idempotent"
python3 - "$tmp_root/chrome-mcp.json" <<'PY'
import json, sys
servers=json.load(open(sys.argv[1]))['mcpServers']
assert set(servers) == {'keep', 'browser-chrome-headed', 'browser-chrome-headless'}
assert servers['browser-chrome-headed']['args'] == ['headed']
assert servers['browser-chrome-headless']['idleTimeout'] == 1
PY

# Settings mutation replaces only pi-codex and preserves unrelated data.
printf '{"packages":["git:github.com/blockedby/pi-codex","other-package"],"keep":true}\n' > "$tmp_root/settings.json"
printf '{"defaultProvider":"provider","defaultModel":"model","defaultThinkingLevel":"low"}\n' > "$tmp_root/desired.json"
mkdir -p "$tmp_root/codex"
python3 "$repo_root/scripts/lib/config-json.py" update-settings "$tmp_root/settings.json" "$tmp_root/codex" "$tmp_root/desired.json"
python3 - "$tmp_root/settings.json" <<'PY'
import json, sys
value=json.load(open(sys.argv[1]))
assert value['keep'] is True and value['packages'][1] == 'other-package'
assert value['defaultProvider'] == 'provider'
PY
printf 'pi-setup tests passed\n'
