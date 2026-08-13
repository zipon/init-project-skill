#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
plugin_name="aws-cdk-project-init"
skill_name="init-aws-cdk-project"
plugin_root="$repo_root/$plugin_name"
skill_parent="$plugin_root/skills"
output_dir="${1:-$repo_root/dist}"

version="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1], encoding="utf-8"))["version"])' "$plugin_root/.codex-plugin/plugin.json")"
skill_archive="$output_dir/${skill_name}-skill-${version}.zip"
plugin_archive="$output_dir/${plugin_name}-plugin-${version}.zip"
checksum_file="$output_dir/checksums.sha256"

"$repo_root/scripts/validate.sh"
mkdir -p "$output_dir"
rm -f -- "$skill_archive" "$plugin_archive" "$checksum_file"

(
  cd "$skill_parent"
  COPYFILE_DISABLE=1 zip -q -r "$skill_archive" "$skill_name" \
    -x '*/.DS_Store' '__MACOSX/*'
)

(
  cd "$repo_root"
  COPYFILE_DISABLE=1 zip -q -r "$plugin_archive" "$plugin_name" \
    -x '*/.DS_Store' '__MACOSX/*' "$plugin_name/submission/*"
)

(
  cd "$output_dir"
  shasum -a 256 "$(basename "$skill_archive")" "$(basename "$plugin_archive")" > "$(basename "$checksum_file")"
)

echo "Created:"
echo "  $skill_archive"
echo "  $plugin_archive"
echo "  $checksum_file"
