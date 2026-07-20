#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=lib/runtime-paths.sh
source "$repo_root/scripts/lib/runtime-paths.sh"

tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

fail() {
  echo "runtime resolution test failed: $*" >&2
  exit 1
}

assert_fresh_bash() {
  local mode="$1"
  local user_home="$2"
  local output resolved path_value
  local -a bash_args=()

  if [ "$mode" = "login" ]; then
    bash_args=(--login -i)
  else
    bash_args=(-i)
  fi

  output="$(HOME="$user_home" PATH="$user_home/.vite-plus/bin:/usr/bin:/bin" \
    bash "${bash_args[@]}" -c 'command -v pi; printf "%s\n" "$PATH"' 2>/dev/null)"
  resolved="$(printf '%s\n' "$output" | sed -n '1p')"
  path_value="$(printf '%s\n' "$output" | sed -n '2p')"

  [ "$resolved" = "$user_home/.local/bin/pi" ] || fail "$mode shell resolved $resolved"
  case "$path_value" in
    "$user_home/.local/bin:$user_home/.vite-plus/bin:"*) ;;
    *) fail "$mode shell PATH is not ordered: $path_value" ;;
  esac
}

# npm selection: explicit override, Vite+ preference, then PATH fallback.
npm_home="$tmp_root/npm-home"
path_bin="$tmp_root/path-bin"
override_bin="$tmp_root/override-bin"
mkdir -p "$npm_home/.vite-plus/bin" "$path_bin" "$override_bin"
printf '#!/usr/bin/env bash\nexit 0\n' > "$npm_home/.vite-plus/bin/npm"
printf '#!/usr/bin/env bash\nexit 0\n' > "$path_bin/npm"
printf '#!/usr/bin/env bash\nexit 0\n' > "$override_bin/npm"
chmod +x "$npm_home/.vite-plus/bin/npm" "$path_bin/npm" "$override_bin/npm"

NPM_BIN="$override_bin/npm"
[ "$(resolve_pi_setup_npm "$npm_home")" = "$override_bin/npm" ] || fail "explicit NPM_BIN was not honored"
unset NPM_BIN
PATH="$path_bin:/usr/bin:/bin"
[ "$(resolve_pi_setup_npm "$npm_home")" = "$npm_home/.vite-plus/bin/npm" ] || fail "Vite+ npm was not preferred"
rm "$npm_home/.vite-plus/bin/npm"
[ "$(resolve_pi_setup_npm "$npm_home")" = "$path_bin/npm" ] || fail "PATH npm fallback was not used"

grep -Fq 'NPM_BIN="$(resolve_pi_setup_npm "$LOCAL_USER_HOME")"' "$repo_root/scripts/lib/pi-setup-local-install.sh" || fail "local implementation does not use the resolver"
grep -Fq '"$NPM_BIN" install -g --prefix "$LOCAL_USER_HOME/.local"' "$repo_root/scripts/lib/pi-setup-local-install.sh" || fail "Pi local prefix changed"

# The complete updater must create local Pi even when an executable non-local
# PI_BIN is supplied. The npm stub handles both the global install and later ci.
update_home="$tmp_root/update-home"
update_agent_dir="$update_home/.pi/agent"
update_tools="$tmp_root/update-tools"
external_bin="$tmp_root/external-bin"
npm_log="$tmp_root/npm.log"
mkdir -p "$update_tools" "$external_bin"
cat > "$update_tools/npm" <<'NPM_STUB'
#!/usr/bin/env bash
set -euo pipefail
printf '%s\n' "$*" >> "$NPM_LOG"
prefix=""
previous=""
for argument in "$@"; do
  if [ "$previous" = "--prefix" ]; then
    prefix="$argument"
  fi
  previous="$argument"
done
if [ "${1:-}" = "install" ] && [ -n "$prefix" ]; then
  mkdir -p "$prefix/bin"
  printf '#!/usr/bin/env bash\nprintf "local-pi\\n"\n' > "$prefix/bin/pi"
  chmod +x "$prefix/bin/pi"
fi
NPM_STUB
printf '#!/usr/bin/env bash\nprintf "external-pi\\n"\n' > "$external_bin/pi"
chmod +x "$update_tools/npm" "$external_bin/pi"

HOME="$update_home" LOCAL_USER_HOME="$update_home" PI_AGENT_DIR="$update_agent_dir" \
  PI_BIN="$external_bin/pi" NPM_BIN="$update_tools/npm" NPM_LOG="$npm_log" \
  PATH="$external_bin:/usr/bin:/bin" \
  bash "$repo_root/scripts/pi-setup" local install > "$tmp_root/update-local.log"
[ -x "$update_home/.local/bin/pi" ] || fail "update-local accepted non-local Pi without installing local Pi"
grep -Fq "install -g --prefix $update_home/.local" "$npm_log" || fail "update-local did not use the local prefix"
assert_fresh_bash interactive "$update_home"
assert_fresh_bash login "$update_home"

# Managed startup: preserve content, avoid duplicate blocks, and prove both Bash routes.
bash_home="$tmp_root/bash-home"
mkdir -p "$bash_home/.local/bin" "$bash_home/.vite-plus/bin"
printf '#!/usr/bin/env bash\nprintf "local-pi\\n"\n' > "$bash_home/.local/bin/pi"
printf '#!/usr/bin/env bash\nprintf "vite-pi\\n"\n' > "$bash_home/.vite-plus/bin/pi"
chmod +x "$bash_home/.local/bin/pi" "$bash_home/.vite-plus/bin/pi"
printf '# interactive sentinel\n' > "$bash_home/.bashrc"
printf '# login sentinel\n' > "$bash_home/.bash_profile"

configure_pi_bash_path "$bash_home"
configure_pi_bash_path "$bash_home"

grep -Fq '# interactive sentinel' "$bash_home/.bashrc" || fail ".bashrc content was not preserved"
grep -Fq '# login sentinel' "$bash_home/.bash_profile" || fail ".bash_profile content was not preserved"
[ "$(grep -Fxc '# >>> pi-agent-setup PATH >>>' "$bash_home/.bashrc")" -eq 1 ] || fail ".bashrc block is not idempotent"
[ "$(grep -Fxc '# >>> pi-agent-setup PATH >>>' "$bash_home/.bash_profile")" -eq 1 ] || fail ".bash_profile block is not idempotent"

assert_fresh_bash interactive "$bash_home"
assert_fresh_bash login "$bash_home"

deduped_path="$(HOME="$bash_home" PATH="$bash_home/.local/bin:$bash_home/.vite-plus/bin:$bash_home/.local/bin:/usr/bin:/bin" \
  bash -c '. "$HOME/.config/pi-agent-setup/bash-path.sh"; . "$HOME/.config/pi-agent-setup/bash-path.sh"; printf "%s\n" "$PATH"')"
[ "$(printf '%s' "$deduped_path" | tr ':' '\n' | grep -Fxc "$bash_home/.local/bin")" -eq 1 ] || fail ".local/bin was duplicated"
[ "$(printf '%s' "$deduped_path" | tr ':' '\n' | grep -Fxc "$bash_home/.vite-plus/bin")" -eq 1 ] || fail ".vite-plus/bin was duplicated"

# Do not create .bash_profile when Bash already uses an existing login file.
profile_home="$tmp_root/profile-home"
mkdir -p "$profile_home"
printf '# profile sentinel\n' > "$profile_home/.profile"
configure_pi_bash_path "$profile_home"
[ ! -e "$profile_home/.bash_profile" ] || fail "existing .profile was shadowed"
grep -Fq '# profile sentinel' "$profile_home/.profile" || fail ".profile content was not preserved"
grep -Fq '# >>> pi-agent-setup PATH >>>' "$profile_home/.profile" || fail ".profile was not configured"
HOME="$profile_home" sh -c '. "$HOME/.profile"' || fail ".profile block is not safe for non-Bash shells"

# Reject malformed owned blocks before changing any other startup surface.
malformed_rc_home="$tmp_root/malformed-rc-home"
mkdir -p "$malformed_rc_home"
printf '# >>> pi-agent-setup PATH >>>\n' > "$malformed_rc_home/.bashrc"
printf '# untouched login\n' > "$malformed_rc_home/.bash_profile"
if configure_pi_bash_path "$malformed_rc_home" 2>/dev/null; then
  fail "malformed .bashrc did not fail configuration"
fi
[ "$(cat "$malformed_rc_home/.bash_profile")" = '# untouched login' ] || fail "login file changed after malformed .bashrc"
[ ! -e "$malformed_rc_home/.config/pi-agent-setup/bash-path.sh" ] || fail "managed file created after malformed .bashrc"

malformed_login_home="$tmp_root/malformed-login-home"
mkdir -p "$malformed_login_home"
printf '# untouched interactive\n' > "$malformed_login_home/.bashrc"
printf '# >>> pi-agent-setup PATH >>>\n' > "$malformed_login_home/.bash_profile"
if configure_pi_bash_path "$malformed_login_home" 2>/dev/null; then
  fail "malformed .bash_profile did not fail configuration"
fi
[ "$(cat "$malformed_login_home/.bashrc")" = '# untouched interactive' ] || fail ".bashrc changed after malformed login block"
[ ! -e "$malformed_login_home/.config/pi-agent-setup/bash-path.sh" ] || fail "managed file created after malformed login block"

printf 'runtime resolution tests passed\n'
