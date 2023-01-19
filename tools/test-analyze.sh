#!/bin/bash

set -euo pipefail

readonly swiftlint="$RUNFILES_DIR/_main/swiftlint"
if [[ ! -x "$swiftlint" ]]; then
  echo "SwiftLint not found at $swiftlint"
  exit 1
fi

# Change to workspace directory
cd "$(dirname "$(readlink Package.swift)")"
swift build --build-tests
"$swiftlint" analyze --strict --compile-commands ".build/debug.yaml"
