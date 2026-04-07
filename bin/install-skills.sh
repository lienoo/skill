#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SOURCE_ROOT="${SOURCE_ROOT:-$REPO_ROOT/skills}"
SKILLS=("handoff" "resume-handoff")

usage() {
  cat <<'EOF'
Usage: bin/install-skills.sh [--target <skills_dir>]

Installs:
  - handoff
  - resume-handoff

Default target selection:
  1) ~/.codex/skills if it exists
  2) ~/.agents/skills if ~/.codex/skills does not exist and ~/.agents/skills exists
  3) create ~/.codex/skills when neither exists
EOF
}

die() {
  echo "Error: $*" >&2
  exit 1
}

expand_tilde() {
  local value="$1"
  if [[ "$value" == "~" ]]; then
    printf '%s\n' "$HOME"
    return 0
  fi
  if [[ "$value" == "~/"* ]]; then
    printf '%s/%s\n' "$HOME" "${value#~/}"
    return 0
  fi
  printf '%s\n' "$value"
}

target_dir=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      shift
      [[ $# -gt 0 ]] || die "--target requires a value"
      target_dir="$(expand_tilde "$1")"
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      die "unknown argument: $1"
      ;;
  esac
  shift
done

if [[ -n "$target_dir" ]]; then
  [[ -d "$target_dir" ]] || die "target path is not a directory: $target_dir"
else
  codex_target="$HOME/.codex/skills"
  agents_target="$HOME/.agents/skills"
  if [[ -d "$codex_target" ]]; then
    target_dir="$codex_target"
  elif [[ -d "$agents_target" ]]; then
    target_dir="$agents_target"
  else
    mkdir -p "$codex_target"
    target_dir="$codex_target"
  fi
fi

for skill in "${SKILLS[@]}"; do
  src="$SOURCE_ROOT/$skill"
  [[ -d "$src" ]] || die "missing source skill directory: $src"
done

for skill in "${SKILLS[@]}"; do
  dest="$target_dir/$skill"
  [[ ! -e "$dest" ]] || die "target skill already exists: $dest (remove or move it manually first)"
done

for skill in "${SKILLS[@]}"; do
  cp -R "$SOURCE_ROOT/$skill" "$target_dir/$skill"
done

echo "Installed skills to: $target_dir"
for skill in "${SKILLS[@]}"; do
  echo " - $skill"
done
