#!/bin/bash

set -euo pipefail

readonly swiftlint="$RUNFILES_DIR/SwiftLint/swiftlint"
readonly swiftpm_yaml="$RUNFILES_DIR/SwiftLint/swiftpm.yaml"
cd "$PROJECT_ROOT"
"$swiftlint" analyze --strict --compile-commands "$swiftpm_yaml"
exit 1
