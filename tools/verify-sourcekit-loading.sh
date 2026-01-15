#!/usr/bin/env bash
set -euo pipefail

bin="${1:-bazel-bin/swiftlint}"
paths_to_lint="${2:-.}"

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "This script is Linux-only (requires /proc/<pid>/maps)."
  exit 0
fi

if [[ ! -d /proc ]]; then
  echo "Expected /proc to be available."
  exit 1
fi

if [[ ! -x "$bin" ]]; then
  echo "Expected SwiftLint binary at '$bin'"
  exit 1
fi

sourcekit_regex="${SOURCEKIT_REGEX:-sourcekit|libsourcekitd|libsourcekitdInProc}"

run_and_assert_sourcekit() {
  local label="$1"; shift
  local expect_loaded="$1"; shift

  echo "::group::${label}"
  echo "Running: $*"

  "$@" &
  local pid=$!

  local seen=0
  local matched_lines=""

  # Poll until the process exits. The lint run should be long enough to observe mappings.
  while kill -0 "$pid" 2>/dev/null; do
    if [[ -r "/proc/$pid/maps" ]]; then
      matched_lines="$(grep -iE "$sourcekit_regex" "/proc/$pid/maps" || true)"
      if [[ -n "$matched_lines" ]]; then
        seen=1
        if [[ "$expect_loaded" == "loaded" ]]; then
          break
        fi
      fi
    fi
    sleep 0.05
  done

  wait "$pid"
  local rc=$?

  if [[ $rc -ne 0 ]]; then
    echo "Command failed (exit code $rc)"
    exit $rc
  fi

  case "$expect_loaded" in
    loaded)
      if [[ $seen -ne 1 ]]; then
        echo "Expected SourceKit to be loaded but it was not observed in /proc/<pid>/maps"
        exit 1
      fi
      ;;
    not-loaded)
      if [[ $seen -ne 0 ]]; then
        echo "Expected SourceKit NOT to be loaded but it was observed in /proc/<pid>/maps"
        echo "$matched_lines" || true
        exit 1
      fi
      ;;
    *)
      echo "Invalid expect_loaded='$expect_loaded'"
      exit 1
      ;;
  esac

  echo "OK: SourceKit '$expect_loaded'"
  echo "::endgroup::"
}

# Use a SourceKit-dependent rule to make the "normal" case deterministic.
common_lint_args=(--quiet --no-cache --only-rule statement_position "$paths_to_lint")

run_and_assert_sourcekit "normal" "loaded" \
  "$bin" lint "${common_lint_args[@]}"

run_and_assert_sourcekit "flag" "not-loaded" \
  "$bin" lint --disable-sourcekit "${common_lint_args[@]}"

run_and_assert_sourcekit "env" "not-loaded" \
  env SWIFTLINT_DISABLE_SOURCEKIT=1 "$bin" lint "${common_lint_args[@]}"
