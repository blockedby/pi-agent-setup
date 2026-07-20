#!/usr/bin/env bash

pi_setup_prepare_remote_dir() {
  local host="$1" remote_dir="$2"
  shift 2
  ssh "$host" "rm -rf '$remote_dir' && mkdir -p '$remote_dir'"
  while [ "$#" -gt 0 ]; do
    ssh "$host" "mkdir -p '$remote_dir/$1'"
    shift
  done
}

pi_setup_stage_remote() {
  local host="$1" source="$2" remote_path="$3"
  rsync -a "$source" "$host:$remote_path"
}

pi_setup_cleanup_remote_dir() {
  local host="$1" remote_dir="$2"
  ssh "$host" "rm -rf '$remote_dir'" >/dev/null 2>&1 || true
}
