#!/usr/bin/env bash

# Resolve npm for Pi setup. An explicit override remains authoritative; otherwise
# prefer Vite+'s npm so the Node runtime is deterministic across installer runs.
resolve_pi_setup_npm() {
  local user_home="$1"

  if [ -n "${NPM_BIN:-}" ]; then
    printf '%s\n' "$NPM_BIN"
  elif [ -x "$user_home/.vite-plus/bin/npm" ]; then
    printf '%s\n' "$user_home/.vite-plus/bin/npm"
  else
    command -v npm || true
  fi
}

# Add one narrowly owned source block to each Bash startup route. The managed
# file is replaced on updates, while existing startup-file content is preserved.
configure_pi_bash_path() {
  local user_home="$1"
  local managed_dir="$user_home/.config/pi-agent-setup"
  local managed_file="$managed_dir/bash-path.sh"
  local managed_tmp="$managed_file.tmp.$$"
  local login_file

  # Bash login shells read only the first existing file in this sequence.
  if [ -e "$user_home/.bash_profile" ]; then
    login_file="$user_home/.bash_profile"
  elif [ -e "$user_home/.bash_login" ]; then
    login_file="$user_home/.bash_login"
  elif [ -e "$user_home/.profile" ]; then
    login_file="$user_home/.profile"
  else
    login_file="$user_home/.bash_profile"
  fi

  # Validate every startup surface before changing any of them. A malformed
  # owned block must stop the operation rather than leave partial setup behind.
  _pi_agent_setup_validate_source "$user_home/.bashrc" || return 1
  _pi_agent_setup_validate_source "$login_file" || return 1

  mkdir -p "$managed_dir"
  cat > "$managed_tmp" <<'BASH_PATH'
# Managed by pi-agent-setup. Keep Pi outside Vite+'s package directories.
_pi_agent_setup_prepend_path() {
  local entry="$1"

  if [ "${PATH-}" = "$entry" ]; then
    PATH=""
  else
    while [[ ":${PATH-}:" == *":$entry:"* ]]; do
      case "${PATH-}" in
        "$entry":*) PATH="${PATH#"$entry":}" ;;
        *:"$entry":*) PATH="${PATH//:"$entry":/:}" ;;
        *:"$entry") PATH="${PATH%:"$entry"}" ;;
        *) break ;;
      esac
    done
  fi

  if [ -n "${PATH-}" ]; then
    PATH="$entry:$PATH"
  else
    PATH="$entry"
  fi
}

_pi_agent_setup_prepend_path "$HOME/.vite-plus/bin"
_pi_agent_setup_prepend_path "$HOME/.local/bin"
unset -f _pi_agent_setup_prepend_path
export PATH
BASH_PATH
  chmod 0644 "$managed_tmp"
  mv -f "$managed_tmp" "$managed_file"

  _pi_agent_setup_ensure_source "$user_home/.bashrc"
  _pi_agent_setup_ensure_source "$login_file"
}

_pi_agent_setup_expected_block() {
  cat <<'SOURCE_BLOCK'
# >>> pi-agent-setup PATH >>>
if [ -n "${BASH_VERSION:-}" ] && [ -r "$HOME/.config/pi-agent-setup/bash-path.sh" ]; then
  . "$HOME/.config/pi-agent-setup/bash-path.sh"
fi
# <<< pi-agent-setup PATH <<<
SOURCE_BLOCK
}

_pi_agent_setup_validate_source() {
  local startup_file="$1"
  local begin_marker="# >>> pi-agent-setup PATH >>>"
  local end_marker="# <<< pi-agent-setup PATH <<<"
  local expected_block
  local existing_block=""
  local begin_count=0
  local end_count=0

  expected_block="$(_pi_agent_setup_expected_block)"
  if [ -f "$startup_file" ]; then
    begin_count="$(grep -Fxc "$begin_marker" "$startup_file" || true)"
    end_count="$(grep -Fxc "$end_marker" "$startup_file" || true)"
    existing_block="$(sed -n '\|^# >>> pi-agent-setup PATH >>>$|,\|^# <<< pi-agent-setup PATH <<<$|p' "$startup_file")"
  fi

  if { [ "$begin_count" -eq 0 ] && [ "$end_count" -eq 0 ] && [ -z "$existing_block" ]; } ||
    { [ "$begin_count" -eq 1 ] && [ "$end_count" -eq 1 ] && [ "$existing_block" = "$expected_block" ]; }; then
    return 0
  fi

  echo "Refusing to modify malformed pi-agent-setup PATH block in $startup_file" >&2
  return 1
}

_pi_agent_setup_ensure_source() {
  local startup_file="$1"
  local expected_block
  local existing_block=""

  _pi_agent_setup_validate_source "$startup_file" || return 1
  expected_block="$(_pi_agent_setup_expected_block)"
  if [ -f "$startup_file" ]; then
    existing_block="$(sed -n '\|^# >>> pi-agent-setup PATH >>>$|,\|^# <<< pi-agent-setup PATH <<<$|p' "$startup_file")"
  fi
  if [ "$existing_block" = "$expected_block" ]; then
    return 0
  fi

  if [ -s "$startup_file" ] && [ -n "$(tail -c 1 "$startup_file")" ]; then
    printf '\n' >> "$startup_file"
  fi
  _pi_agent_setup_expected_block >> "$startup_file"
}
