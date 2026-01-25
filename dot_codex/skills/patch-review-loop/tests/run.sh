#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPTS_DIR="$ROOT_DIR/scripts"
TESTS_DIR="$ROOT_DIR/tests"
TMP_BASE="$TESTS_DIR/tmp"

mkdir -p "$TMP_BASE"

failures=0

die() {
  echo "fatal: $*" >&2
  exit 2
}

note() {
  echo "==> $*"
}

assert_eq() {
  local expected="${1:?expected}"
  local actual="${2:?actual}"
  local msg="${3:-}"
  if [[ "$expected" != "$actual" ]]; then
    echo "ASSERT_EQ failed${msg:+: $msg}" >&2
    echo "  expected: $expected" >&2
    echo "    actual: $actual" >&2
    return 1
  fi
}

assert_file_exists() {
  local path="${1:?path}"
  if [[ ! -f "$path" ]]; then
    echo "ASSERT_FILE_EXISTS failed: $path" >&2
    return 1
  fi
}

assert_contains() {
  local haystack="${1:?haystack}"
  local needle="${2:?needle}"
  local msg="${3:-}"
  if ! grep -Fq -- "$needle" <<<"$haystack"; then
    echo "ASSERT_CONTAINS failed${msg:+: $msg}" >&2
    echo "  missing: $needle" >&2
    return 1
  fi
}

mk_workdir() {
  local name="${1:-work}"
  local dir="$TMP_BASE/${name}_$(date +%s)_$$"
  mkdir -p "$dir"
  echo "$dir"
}

init_git_repo() {
  local dir="${1:?dir}"
  git -C "$dir" init -q
  git -C "$dir" config user.email "test@example.com"
  git -C "$dir" config user.name "Patch Review Loop Tests"
}

git_commit() {
  local dir="${1:?dir}"
  local msg="${2:?msg}"
  local file="${3:?file}"
  local content="${4:-$msg}"
  printf "%s\n" "$content" >"$dir/$file"
  git -C "$dir" add -A
  git -C "$dir" commit -q -m "$msg"
}

run_test() {
  local name="${1:?name}"
  shift

  note "$name"
  if "$@"; then
    echo "PASS $name"
  else
    echo "FAIL $name" >&2
    failures=$((failures + 1))
  fi
}

test_sanitize() {
  local out
  out="$(python3 "$SCRIPTS_DIR/sanitize.py" " Hello, World! ")"
  assert_eq "hello_world" "$out" "basic normalization"

  out="$(python3 "$SCRIPTS_DIR/sanitize.py" "A/B\\C:D*E?F\"G<H>I|J")"
  assert_eq "abcdefghij" "$out" "strip illegal characters"

  out="$(python3 "$SCRIPTS_DIR/sanitize.py" "")"
  assert_eq "patch" "$out" "empty input fallback"

  out="$(python3 "$SCRIPTS_DIR/sanitize.py" "$(printf 'x%.0s' {1..200})")"
  assert_eq "$(printf 'x%.0s' {1..60})" "$out" "truncate to 60 chars"
}

test_count_patch_commits() (
  set -euo pipefail
  local dir
  dir="$(mk_workdir "count")"
  trap 'rm -rf "$dir"' EXIT

  init_git_repo "$dir"
  git_commit "$dir" "patch: one" "a.txt"
  git_commit "$dir" "patch: two" "b.txt"
  git_commit "$dir" "feat: stop" "c.txt"

  local n
  n="$(cd "$dir" && bash "$SCRIPTS_DIR/count_patch_commits.sh" 50)"
  assert_eq "0" "$n" "HEAD is non-patch, should be 0"

  git -C "$dir" reset -q --hard HEAD~1
  n="$(cd "$dir" && bash "$SCRIPTS_DIR/count_patch_commits.sh" 50)"
  assert_eq "2" "$n" "consecutive patch commits from HEAD"
)

test_export_patch() (
  set -euo pipefail
  local dir
  dir="$(mk_workdir "export")"
  trap 'rm -rf "$dir"' EXIT

  init_git_repo "$dir"
  git_commit "$dir" "patch: export works" "a.txt"

  local out
  out="$(cd "$dir" && bash "$SCRIPTS_DIR/export_patch.sh")"

  [[ "$out" == .patches/* ]] || {
    echo "expected .patches/*, got: $out" >&2
    return 1
  }
  assert_file_exists "$dir/$out"

  local content
  content="$(cat "$dir/$out")"
  assert_contains "$content" "Subject:" "format-patch metadata present"
  assert_contains "$content" "export works" "subject includes summary"

  [[ ! -d "$dir/.codex/patches" ]] || {
    echo "did not expect .codex/patches to exist" >&2
    return 1
  }
)

test_scan_review() (
  set -euo pipefail
  local dir
  dir="$(mk_workdir "scan")"
  trap 'rm -rf "$dir"' EXIT

  cat >"$dir/sample.diff" <<'EOF'
line1
### CV: general comment
code a
code b
### CV:2 points to two lines down
x
TARGET
end
EOF

  local got expected
  got="$(bash "$SCRIPTS_DIR/scan_review.sh" "$dir/sample.diff")"
  expected=$'2:### CV: general comment\n3:code a\n4:code b\n\n5:### CV:2 points to two lines down\n7:TARGET'
  assert_eq "$expected" "$got" "scan output"

  cat >"$dir/oob.diff" <<'EOF'
### CV:99 out of range
one
EOF
  got="$(bash "$SCRIPTS_DIR/scan_review.sh" "$dir/oob.diff")"
  assert_contains "$got" "(out of range)" "out-of-range marker"
)

main() {
  command -v git >/dev/null || die "git not found"
  command -v python3 >/dev/null || die "python3 not found"

  run_test "sanitize.py" test_sanitize
  run_test "count_patch_commits.sh" test_count_patch_commits
  run_test "export_patch.sh" test_export_patch
  run_test "scan_review.sh" test_scan_review

  if [[ "$failures" -ne 0 ]]; then
    echo "$failures test(s) failed" >&2
    exit 1
  fi
}

main "$@"
