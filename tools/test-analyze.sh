#!/bin/bash

set -euo pipefail

readonly swiftlint="$RUNFILES_DIR/SwiftLint/swiftlint"
readonly swiftpm_yaml="$RUNFILES_DIR/SwiftLint/swiftpm.yaml"
# Change to workspace directory
cd "$(dirname "$(readlink Package.swift)")"
swift build
"$swiftlint" analyze --strict --compile-commands ".build/debug.yaml"
