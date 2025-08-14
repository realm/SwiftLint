#!/bin/bash

set -eo pipefail

pushd "$(dirname "${BASH_SOURCE[0]}")/.." > /dev/null

if [[ "$TARGETPLATFORM" = "linux/amd64" ]]; then
    ARCH="x86_64"
    STRIP_CMD="strip"
elif [[ "$TARGETPLATFORM" = "linux/arm64" ]]; then
    ARCH="aarch64"
    STRIP_CMD="aarch64-linux-gnu-strip"
else
    echo "Unsupported target platform: $TARGETPLATFORM"
    exit 1
fi

BUILD_ARGS=(
    --product swiftlint
    --configuration release
    --swift-sdk "${ARCH}-swift-linux-musl"
    -Xswiftc -I.
    -Xswiftc -static-stdlib
    -Xlinker -l_CFURLSessionInterface
    -Xlinker -l_CFXMLInterface
    -Xlinker -lcurl
    -Xlinker -lxml2
    -Xlinker -fuse-ld=lld
    -Xlinker -L/usr/lib/swift/linux
    -Xlinker -S
)

swift build "${BUILD_ARGS[@]}"
mv ".build/release/swiftlint" "swiftlint_linux_${ARCH}"
${STRIP_CMD} "swiftlint_linux_${ARCH}"
