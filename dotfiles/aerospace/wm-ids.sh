#!/usr/bin/env bash
set -euo pipefail

script_dir="$(
  cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd
)"
# shellcheck source=./wm-id-helper.sh
source "$script_dir/wm-id-helper.sh"

usage() {
  cat <<'EOF'
Usage:
  wm-ids add <id>
  wm-ids remove <id>
  wm-ids has <id>
  wm-ids contains <id>
  wm-ids list
  wm-ids count
  wm-ids clear

Environment:
  WM_IDS_DB_PATH   Full path to SQLite DB
EOF
}

if [[ $# -lt 1 ]]; then
  usage
  exit 1
fi

case "$1" in
add)
  [[ $# -eq 2 ]] || {
    usage
    exit 1
  }
  wm_ids_add "$2"
  ;;
remove)
  [[ $# -eq 2 ]] || {
    usage
    exit 1
  }
  wm_ids_remove "$2"
  ;;
has)
  [[ $# -eq 2 ]] || {
    usage
    exit 1
  }
  wm_ids_has "$2"
  ;;
contains)
  [[ $# -eq 2 ]] || {
    usage
    exit 1
  }
  if wm_ids_contains "$2"; then
    exit 0
  else
    exit 1
  fi
  ;;
list)
  [[ $# -eq 1 ]] || {
    usage
    exit 1
  }
  wm_ids_list
  ;;
count)
  [[ $# -eq 1 ]] || {
    usage
    exit 1
  }
  wm_ids_count
  ;;
clear)
  [[ $# -eq 1 ]] || {
    usage
    exit 1
  }
  wm_ids_clear
  ;;
-h | --help | help)
  usage
  ;;
*)
  usage
  exit 1
  ;;
esac
