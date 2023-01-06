#!/bin/bash

set -euo pipefail

readonly old_tag="$(sed -n 's/.* exact: "\(.*\)".*/\1/p' Package.swift)"
if [ $# -eq 0 ]; then
  readonly new_tag="$(curl -s -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github+json" "https://api.github.com/repos/apple/swift-syntax/releases?per_page=1" | sed -n 's/.*tag_name":"\([^"]*\)".*/\1/p')"
else
  readonly new_tag="$1"
fi

if [[ "$old_tag" == "$new_tag" ]]; then
  echo "SwiftSyntax is already up to date at $new_tag"
  exit 0
fi

echo "Updating SwiftSyntax from $old_tag to $new_tag"
if [[ "${GITHUB_ACTIONS-}" == "true" ]]; then
  echo "needs_update=true" >> $GITHUB_OUTPUT
  echo "old_tag=$old_tag" >> $GITHUB_OUTPUT
  echo "new_tag=$new_tag" >> $GITHUB_OUTPUT
fi

# $1 — string to match
# $2 — string to replace
# $3 — file
function replace() {
  if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/$1/$2/g" "$3"
  else
    sed -i "s/$1/$2/g" "$3"
  fi
}

replace "$old_tag" "$new_tag" Package.swift
swift package update

replace "$old_tag" "$new_tag" bazel/repos.bzl

readonly url="https://github.com/apple/swift-syntax/archive/refs/tags/$new_tag.tar.gz"
output="$(mktemp -d)/download"
if ! curl -s --location --fail --output "$output" "$url"; then
  echo "error: failed to download $url" >&2
  exit 1
fi

readonly old_sha256="$(grep "SwiftSyntax sha256" bazel/repos.bzl | sed -nr 's/.*\"([a-f0-9]{64})\".*/\1/p')"
readonly new_sha256="$(shasum -a 256 "$output" | cut -d " " -f1 | xargs)"
replace "$old_sha256" "$new_sha256" bazel/repos.bzl
