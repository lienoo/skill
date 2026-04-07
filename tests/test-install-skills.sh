#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
INSTALL_SCRIPT="$ROOT_DIR/bin/install-skills.sh"

fail() {
  echo "FAIL: $*" >&2
  exit 1
}

assert_exists() {
  local path="$1"
  [[ -e "$path" ]] || fail "expected path to exist: $path"
}

assert_not_exists() {
  local path="$1"
  [[ ! -e "$path" ]] || fail "expected path to not exist: $path"
}

assert_contains() {
  local file="$1"
  local needle="$2"
  grep -Fq "$needle" "$file" || fail "expected '$needle' in $file"
}

run_expect_fail() {
  set +e
  "$@"
  local code=$?
  set -e
  [[ $code -ne 0 ]] || fail "expected command to fail: $*"
}

test_script_exists_and_executable() {
  [[ -x "$INSTALL_SCRIPT" ]] || fail "install script missing or not executable: $INSTALL_SCRIPT"
}

test_default_prefers_codex() {
  local tmp
  tmp="$(mktemp -d)"
  local home="$tmp/home"
  mkdir -p "$home/.codex/skills" "$home/.agents/skills"

  HOME="$home" "$INSTALL_SCRIPT" >"$tmp/out.log" 2>"$tmp/err.log"

  assert_exists "$home/.codex/skills/handoff/SKILL.md"
  assert_exists "$home/.codex/skills/resume-handoff/SKILL.md"
  assert_not_exists "$home/.agents/skills/handoff"
}

test_fallback_to_agents() {
  local tmp
  tmp="$(mktemp -d)"
  local home="$tmp/home"
  mkdir -p "$home/.agents/skills"

  HOME="$home" "$INSTALL_SCRIPT" >"$tmp/out.log" 2>"$tmp/err.log"

  assert_exists "$home/.agents/skills/handoff/SKILL.md"
  assert_exists "$home/.agents/skills/resume-handoff/SKILL.md"
  assert_not_exists "$home/.codex/skills/handoff"
}

test_create_codex_if_no_target_exists() {
  local tmp
  tmp="$(mktemp -d)"
  local home="$tmp/home"
  mkdir -p "$home"

  HOME="$home" "$INSTALL_SCRIPT" >"$tmp/out.log" 2>"$tmp/err.log"

  assert_exists "$home/.codex/skills/handoff/SKILL.md"
  assert_exists "$home/.codex/skills/resume-handoff/SKILL.md"
}

test_explicit_target_must_be_directory() {
  local tmp
  tmp="$(mktemp -d)"
  local home="$tmp/home"
  mkdir -p "$home"
  local target="$tmp/not-a-directory"
  : >"$target"

  run_expect_fail env HOME="$home" "$INSTALL_SCRIPT" --target "$target" >"$tmp/out.log" 2>"$tmp/err.log"
  assert_contains "$tmp/err.log" "not a directory"
}

test_explicit_target_installs_to_requested_dir() {
  local tmp
  tmp="$(mktemp -d)"
  local home="$tmp/home"
  local target="$tmp/custom-skills"
  mkdir -p "$home" "$target"

  HOME="$home" "$INSTALL_SCRIPT" --target "$target" >"$tmp/out.log" 2>"$tmp/err.log"

  assert_exists "$target/handoff/SKILL.md"
  assert_exists "$target/resume-handoff/SKILL.md"
  assert_not_exists "$home/.codex/skills/handoff"
  assert_not_exists "$home/.agents/skills/handoff"
}

test_conflict_exits_nonzero() {
  local tmp
  tmp="$(mktemp -d)"
  local home="$tmp/home"
  mkdir -p "$home/.codex/skills/handoff"

  run_expect_fail env HOME="$home" "$INSTALL_SCRIPT" >"$tmp/out.log" 2>"$tmp/err.log"
  assert_contains "$tmp/err.log" "already exists"
  assert_contains "$tmp/err.log" "remove or move"
}

test_missing_source_dirs_fail() {
  local tmp
  tmp="$(mktemp -d)"
  local home="$tmp/home"
  mkdir -p "$home/.codex/skills"
  local missing_root="$tmp/missing-source"
  mkdir -p "$missing_root"

  run_expect_fail env HOME="$home" SOURCE_ROOT="$missing_root" "$INSTALL_SCRIPT" >"$tmp/out.log" 2>"$tmp/err.log"
  assert_contains "$tmp/err.log" "missing source skill directory"
}

main() {
  test_script_exists_and_executable
  test_default_prefers_codex
  test_fallback_to_agents
  test_create_codex_if_no_target_exists
  test_explicit_target_must_be_directory
  test_explicit_target_installs_to_requested_dir
  test_conflict_exits_nonzero
  test_missing_source_dirs_fail
  echo "PASS: install-skills tests"
}

main "$@"
