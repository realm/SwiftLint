#!/bin/bash

set -eo pipefail

pushd "$(dirname "${BASH_SOURCE[0]}")/.." > /dev/null

if [[ "$TARGETPLATFORM" = "linux/amd64" ]]; then
    ARCH="x86_64"
elif [[ "$TARGETPLATFORM" = "linux/arm64" ]]; then
    ARCH="aarch64"
else
    echo "Unsupported target platform: $TARGETPLATFORM"
    exit 1
fi

BUILD_ARGS=(
    --product swiftlint
    --configuration release
    -Xswiftc -I.
    -Xswiftc -static-stdlib
    -Xlinker -l_CFURLSessionInterface
    -Xlinker -l_CFXMLInterface
    -Xlinker -lcurl
    -Xlinker -lxml2
    -Xlinker -fuse-ld=lld
    -Xlinker -L/usr/lib/swift/linux
)

swift build "${BUILD_ARGS[@]}"
mv "$(swift build "${BUILD_ARGS[@]}" --show-bin-path)/swiftlint" "swiftlint_linux_${ARCH}"
strip "swiftlint_linux_${ARCH}"

popd > /dev/null
