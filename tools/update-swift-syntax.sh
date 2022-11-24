#!/bin/bash

set -euo pipefail

readonly old_commit="$(grep "apple/swift-syntax" Package.swift | sed -nr 's/.*revision: \"([a-f0-9]{40})\"),$/\1/p')"
if [ $# -eq 0 ]; then
  readonly new_commit="$(curl -s -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github.VERSION.sha" "https://api.github.com/repos/apple/swift-syntax/commits/main")"
else
  readonly new_commit="$1"
fi

if [[ "$old_commit" == "$new_commit" ]]; then
  echo "SwiftSyntax is already up to date"
  exit 0
fi

echo "Updating SwiftSyntax from $old_commit to $new_commit"
if [[ "${GITHUB_ACTIONS-}" == "true" ]]; then
  echo "old_commit=$old_commit" >> $GITHUB_OUTPUT
  echo "new_commit=$new_commit" >> $GITHUB_OUTPUT
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

replace "$old_commit" "$new_commit" Package.swift
replace "$old_commit" "$new_commit" Package.resolved
replace "$old_commit" "$new_commit" bazel/repos.bzl

readonly url="https://github.com/apple/swift-syntax/archive/$new_commit.tar.gz"
output="$(mktemp -d)/download"
if ! curl -s --location --fail --output "$output" "$url"; then
  echo "error: failed to download $url" >&2
  exit 1
fi

readonly old_sha256="$(grep "SwiftSyntax sha256" bazel/repos.bzl | sed -nr 's/.*\"([a-f0-9]{64})\".*/\1/p')"
readonly new_sha256="$(shasum -a 256 "$output" | cut -d " " -f1 | xargs)"
replace "$old_sha256" "$new_sha256" bazel/repos.bzl
