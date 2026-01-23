#!/bin/bash

set -euo pipefail

version="$1"

# Generate Release Notes

release_notes=$(mktemp)
./tools/generate-release-notes.sh "$version" > "$release_notes"

# Create GitHub Release

release_title="$(sed -n '3s/^## //p' CHANGELOG.md)"
gh release create "$version" --title "$release_title" -F "$release_notes" --draft --verify-tag  \
    "bazel.tar.gz"                                                                              \
    "bazel.tar.gz.sha256"                                                                       \
    "portable_swiftlint.zip#Universal macOS Binary"                                             \
    "SwiftLint.pkg#Universal macOS Installer"                                                   \
    "swiftlint_linux_amd64.zip#AMD64 Linux Binaries"                                            \
    "swiftlint_linux_arm64.zip#ARM64 Linux Binaries"                                            \
    "SwiftLintBinary.artifactbundle.zip"

rm "$release_notes"
