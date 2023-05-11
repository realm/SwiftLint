#!/bin/bash

set -euo pipefail

version="$1"

# Generate Release Notes

release_notes=$(mktemp)
./tools/generate-release-notes.sh "$version" > "$release_notes"

# Create GitHub Release

release_title="$(sed -n '1s/^## //p' CHANGELOG.md)"
gh release create "$version" --title "$release_title" -F "$release_notes"

rm "$release_notes"

# Upload release assets

files_to_upload=(
  "bazel.tar.gz"
  "bazel.tar.gz.sha256"
  "portable_swiftlint.zip"
  "SwiftLint.pkg"
  "SwiftLintBinary-macos.artifactbundle.zip"
)

for file in "${files_to_upload[@]}"; do
  gh release upload "$version" "$file"
done
