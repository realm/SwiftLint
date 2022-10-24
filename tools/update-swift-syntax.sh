#!/bin/bash

set -euo pipefail

readonly old_commit="$(grep "apple/swift-syntax" Package.swift | sed -nr 's/.*revision\(\"([a-f0-9]{40})\"\).*/\1/p')"
readonly new_commit="$(curl -s -H "Authorization: token $GITHUB_TOKEN" -H "Accept: application/vnd.github.VERSION.sha" "https://api.github.com/repos/apple/swift-syntax/commits/main")"

if [[ "$old_commit" == "$new_commit" ]]; then
  echo "SwiftSyntax is already up to date"
  exit 0
fi

echo "Updating SwiftSyntax from $old_commit to $new_commit"

sed -i "s/$old_commit/$new_commit/g" Package.swift
sed -i "s/$old_commit/$new_commit/g" Package.resolved
sed -i "s/$old_commit/$new_commit/g" bazel/repos.bzl

readonly url="https://github.com/apple/swift-syntax/archive/$new_commit.tar.gz"
output="$(mktemp -d)/download"
if ! curl -s --location --fail --output "$output" "$url"; then
  echo "error: failed to download $url" >&2
  exit 1
fi

readonly old_sha256="$(grep "SwiftSyntax sha256" bazel/repos.bzl | sed -nr 's/.*\"([a-f0-9]{64})\".*/\1/p')"
readonly new_sha256="$(shasum -a 256 "$output" | cut -d " " -f1 | xargs)"
sed -i "s/$old_sha256/$new_sha256/g" bazel/repos.bzl
