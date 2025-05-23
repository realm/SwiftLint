#!/bin/bash

set -eo pipefail

pushd "$(dirname "${BASH_SOURCE[0]}")/.." > /dev/null

BUILD_ARGS=(
    --product swiftlint
    --configuration release
    -Xlinker -S
)

if [[ -z "$TARGETPLATFORM" ]]; then
    ARCH="$(uname -m)"
else
    if [[ "$TARGETPLATFORM" = "linux/amd64" ]]; then
        ARCH="x86_64"
    elif [[ "$TARGETPLATFORM" = "linux/arm64" ]]; then
        ARCH="aarch64"
    else
        echo "Unsupported target platform: $TARGETPLATFORM"
        exit 1
    fi
fi
BUILD_ARGS+=(--swift-sdk "${ARCH}-swift-linux-musl")

swift build "${BUILD_ARGS[@]}"
