#!/usr/bin/env bash

pi_setup_require_value() {
  local name="$1" value="$2"
  if [ -z "$value" ]; then
    echo "$name is required" >&2
    return 2
  fi
}

# Resolve a requested home consistently on remote install, verify, and auth
# import. The fallback only applies when the remote shell has no usable HOME.
pi_setup_resolve_home() {
  local requested="$1"
  if [ -n "$requested" ]; then
    if [ -d "$requested" ]; then
      printf '%s\n' "$requested"
    else
      echo "REMOTE_USER_HOME does not exist on target: $requested" >&2
      return 2
    fi
  elif [ -n "${HOME:-}" ] && [ -d "$HOME" ]; then
    printf '%s\n' "$HOME"
  else
    printf '%s\n' /root
  fi
}

pi_setup_require_settings_file() {
  local repo_root="$1" settings_file="$2"
  if [ ! -f "$repo_root/$settings_file" ]; then
    echo "PI_SETTINGS_FILE not found: $settings_file" >&2
    echo "Use settings/pi-settings.example.json or an ignored settings/*.local.json copy." >&2
    return 2
  fi
}
