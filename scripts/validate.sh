#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
plugin_root="$repo_root/aws-cdk-project-init"
skill_root="$plugin_root/skills/init-aws-cdk-project"
check_links=false

if [[ "${1:-}" == "--links" ]]; then
  check_links=true
elif [[ $# -ne 0 ]]; then
  echo "Usage: $0 [--links]" >&2
  exit 2
fi

required_files=(
  "$plugin_root/.codex-plugin/plugin.json"
  "$plugin_root/LICENSE"
  "$plugin_root/PRIVACY.md"
  "$plugin_root/README.md"
  "$plugin_root/SUPPORT.md"
  "$plugin_root/TERMS.md"
  "$plugin_root/assets/composer-icon.png"
  "$plugin_root/assets/logo.png"
  "$skill_root/SKILL.md"
  "$skill_root/agents/openai.yaml"
  "$skill_root/assets/aws-cdk-project-init-logo.png"
  "$skill_root/assets/github-environment-develop.png"
  "$skill_root/assets/github-environment-variables.png"
  "$skill_root/scripts/init_aws_cdk_project.sh"
  "$skill_root/scripts/init_repo.sh"
  "$plugin_root/submission/LISTING.md"
  "$plugin_root/submission/RELEASE_NOTES.md"
  "$plugin_root/submission/STARTER_PROMPTS.md"
  "$plugin_root/submission/SUBMISSION_CHECKLIST.md"
  "$plugin_root/submission/TEST_CASES.md"
  "$repo_root/.agents/plugins/marketplace.json"
)

for path in "${required_files[@]}"; do
  if [[ ! -f "$path" ]]; then
    echo "ERROR: required file is missing: $path" >&2
    exit 1
  fi
done

for script in "$skill_root/scripts/init_aws_cdk_project.sh" "$skill_root/scripts/init_repo.sh"; do
  bash -n "$script"
  if [[ ! -x "$script" ]]; then
    echo "ERROR: script is not executable: $script" >&2
    exit 1
  fi
done

python3 - "$plugin_root/.codex-plugin/plugin.json" "$repo_root/.agents/plugins/marketplace.json" "$skill_root/SKILL.md" "$skill_root/agents/openai.yaml" <<'PY'
import json
import re
import sys
from pathlib import Path

manifest_path = Path(sys.argv[1])
marketplace_path = Path(sys.argv[2])
skill_path = Path(sys.argv[3])
agent_config_path = Path(sys.argv[4])
plugin_root = manifest_path.parent.parent

manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
assert manifest["name"] == "aws-cdk-project-init"
assert re.fullmatch(r"\d+\.\d+\.\d+", manifest["version"])
assert manifest["skills"] == "./skills/"
assert manifest["repository"] == "https://github.com/zipon/init-project-skill"

brand_color = manifest["interface"]["brandColor"]
assert re.fullmatch(r"#[0-9A-Fa-f]{6}", brand_color), "brandColor must be a six-digit hex color"

def linear_channel(value):
    channel = value / 255
    return channel / 12.92 if channel <= 0.04045 else ((channel + 0.055) / 1.055) ** 2.4

red, green, blue = (int(brand_color[index:index + 2], 16) for index in (1, 3, 5))
luminance = (
    0.2126 * linear_channel(red)
    + 0.7152 * linear_channel(green)
    + 0.0722 * linear_channel(blue)
)
contrast_against_white = 1.05 / (luminance + 0.05)
assert contrast_against_white >= 2, (
    f"brandColor {brand_color} has only {contrast_against_white:.2f}:1 contrast against white"
)

agent_config = agent_config_path.read_text(encoding="utf-8")
agent_brand_match = re.search(r'^\s*brand_color:\s*["\']?(#[0-9A-Fa-f]{6})["\']?\s*$', agent_config, re.MULTILINE)
assert agent_brand_match, "agents/openai.yaml must define brand_color"
assert agent_brand_match.group(1).lower() == brand_color.lower(), (
    "plugin manifest brandColor and agents/openai.yaml brand_color must match"
)

for field in ("composerIcon", "logo"):
    asset = manifest["interface"][field]
    assert asset.startswith("./")
    assert (plugin_root / asset[2:]).is_file(), f"missing manifest asset: {asset}"

marketplace = json.loads(marketplace_path.read_text(encoding="utf-8"))
assert marketplace["name"] == "init-project-skill"
entries = {entry["name"]: entry for entry in marketplace["plugins"]}
entry = entries["aws-cdk-project-init"]
assert entry["source"] == {"source": "local", "path": "./aws-cdk-project-init"}
assert entry["policy"] == {
    "installation": "AVAILABLE",
    "authentication": "ON_INSTALL",
}
assert entry["category"] == "Developer Tools"

skill_text = skill_path.read_text(encoding="utf-8")
frontmatter = re.match(r"^---\n(.*?)\n---\n", skill_text, re.DOTALL)
assert frontmatter, "SKILL.md must start with YAML frontmatter"
header = frontmatter.group(1)
name_match = re.search(r"^name:\s*(.+)$", header, re.MULTILINE)
description_match = re.search(r"^description:\s*(.+)$", header, re.MULTILINE)
assert name_match and name_match.group(1).strip() == "init-aws-cdk-project"
assert description_match and description_match.group(1).strip()
PY

if grep -R -n -E 'Polaris|aws-skill-project|init-project-standard|\[TODO:' \
  --exclude='.DS_Store' --exclude-dir='.git' --exclude-dir='dist' "$plugin_root"; then
  echo "ERROR: obsolete naming or a TODO placeholder remains in the plugin" >&2
  exit 1
fi

positive_count="$(awk '/^## Positive test cases/{section="positive"; next} /^## Negative test cases/{section="negative"; next} /^### / && section=="positive"{count++} END{print count+0}' "$plugin_root/submission/TEST_CASES.md")"
negative_count="$(awk '/^## Positive test cases/{section="positive"; next} /^## Negative test cases/{section="negative"; next} /^### / && section=="negative"{count++} END{print count+0}' "$plugin_root/submission/TEST_CASES.md")"
prerequisite_count="$(grep -c '^\- \*\*Reviewer prerequisites:\*\*' "$plugin_root/submission/TEST_CASES.md")"
reason_count="$(grep -c '^\- \*\*Why the plugin should not proceed:\*\*' "$plugin_root/submission/TEST_CASES.md")"

if [[ "$positive_count" -ne 5 || "$negative_count" -ne 3 ]]; then
  echo "ERROR: expected five positive and three negative submission tests" >&2
  exit 1
fi
if [[ "$prerequisite_count" -ne 5 || "$reason_count" -ne 3 ]]; then
  echo "ERROR: reviewer prerequisites or negative-test reasons are incomplete" >&2
  exit 1
fi

if [[ "$check_links" == true ]]; then
  urls=(
    "https://github.com/zipon"
    "https://github.com/zipon/init-project-skill"
    "https://github.com/zipon/init-project-skill/tree/main/aws-cdk-project-init"
    "https://github.com/zipon/init-project-skill/issues"
    "https://github.com/zipon/init-project-skill/releases"
    "https://github.com/zipon/init-project-skill/releases/tag/v1.0.0"
    "https://github.com/zipon/init-project-skill/releases/download/v1.0.0/init-aws-cdk-project-skill-1.0.0.zip"
    "https://github.com/zipon/init-project-skill/releases/download/v1.0.0/aws-cdk-project-init-plugin-1.0.0.zip"
    "https://github.com/zipon/init-project-skill/releases/download/v1.0.0/checksums.sha256"
    "https://github.com/zipon/init-project-skill/blob/main/aws-cdk-project-init/PRIVACY.md"
    "https://github.com/zipon/init-project-skill/blob/main/aws-cdk-project-init/TERMS.md"
    "https://github.com/zipon/init-project-skill/archive/refs/heads/main.zip"
    "https://github.com/zipon/Traceability/tree/v1.0.4"
    "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
    "https://lars-andersson.medium.com/where-the-hell-is-the-git-project-that-owns-this-550bd96dd230"
    "https://platform.openai.com/plugins"
  )
  for url in "${urls[@]}"; do
    status="$(curl -L --silent --show-error --output /dev/null --write-out '%{http_code}' --max-time 30 "$url")"
    if [[ "$status" -eq 403 && ( "$url" == https://lars-andersson.medium.com/* || "$url" == "https://platform.openai.com/plugins" ) ]]; then
      echo "HTTP 403 $url (the site blocks unauthenticated automated probes; verify in a normal browser)"
      continue
    fi
    if [[ "$status" -lt 200 || "$status" -ge 400 ]]; then
      echo "ERROR: URL returned HTTP $status: $url" >&2
      exit 1
    fi
    echo "HTTP $status $url"
  done
fi

echo "Repository validation passed."
