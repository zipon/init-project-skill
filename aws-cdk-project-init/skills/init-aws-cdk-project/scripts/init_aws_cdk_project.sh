#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 <target-directory>" >&2
  exit 2
fi

target_dir="$1"
script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
init_script="$script_dir/init_repo.sh"

if [[ ! -f "$init_script" ]]; then
  echo "ERROR: bundled init script is missing: $init_script" >&2
  exit 1
fi

mkdir -p "$target_dir"

if find "$target_dir" -mindepth 1 -maxdepth 1 | read -r _; then
  echo "ERROR: target directory is not empty: $target_dir" >&2
  exit 1
fi

(
  cd "$target_dir"
  bash "$init_script"
)
