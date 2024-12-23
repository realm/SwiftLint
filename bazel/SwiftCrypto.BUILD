"""
Swift Crypto is an open-source implementation of a substantial portion of the API of
[Apple CryptoKit](https://developer.apple.com/documentation/cryptokit) suitable for
use on Linux platforms. It enables cross-platform or server applications with the
advantages of CryptoKit.

This build overlay is borrowed from aaronsky/asc-swift:
https://github.com/aaronsky/asc-swift/blob/386bb669/bazel/third_party/com_github_apple_swift_crypto/BUILD.overlay
"""

load("@build_bazel_rules_cc//cc:defs.bzl", "cc_library")
load("@build_bazel_rules_swift//swift:swift_interop_hint.bzl", "swift_interop_hint")
load("@build_bazel_rules_swift//swift:swift_library.bzl", "swift_library")

_crypto_non_apple_deps = [
    ":CCryptoBoringSSL",
    ":CCryptoBoringSSLShims",
    ":CryptoBoringWrapper",
]

swift_library(
    name = "Crypto",
    srcs = glob(["Sources/Crypto/**/*.swift"]),
    defines = [
        "MODULE_IS_CRYPTO",
        "CRYPTO_IN_SWIFTPM",
    ] + select({
        "@platforms//os:linux": ["CRYPTO_IN_SWIFTPM_FORCE_BUILD_API"],
        "@platforms//os:android": ["CRYPTO_IN_SWIFTPM_FORCE_BUILD_API"],
        "@platforms//os:windows": ["CRYPTO_IN_SWIFTPM_FORCE_BUILD_API"],
        "@platforms//os:wasi": ["CRYPTO_IN_SWIFTPM_FORCE_BUILD_API"],
        "//conditions:default": [],
    }),
    module_name = "Crypto",
    visibility = ["//visibility:public"],
    deps = select({
        "@platforms//os:linux": _crypto_non_apple_deps,
        "@platforms//os:android": _crypto_non_apple_deps,
        "@platforms//os:windows": _crypto_non_apple_deps,
        "@platforms//os:wasi": _crypto_non_apple_deps,
        "//conditions:default": [],
    }),
)

cc_library(
    name = "CCryptoBoringSSL",
    srcs = glob([
        "Sources/CCryptoBoringSSL/crypto/**/*.c",
        "Sources/CCryptoBoringSSL/crypto/**/*.h",
        "Sources/CCryptoBoringSSL/crypto/**/*.S",
        "Sources/CCryptoBoringSSL/third_party/**/*.h",
        "Sources/CCryptoBoringSSL/third_party/**/*.S",
    ]),
    hdrs = glob(["Sources/CCryptoBoringSSL/include/**/*.h"]),
    aspect_hints = [":CCryptoBoringSSL_interop"],
    includes = ["Sources/CCryptoBoringSSL/include"],
)

swift_interop_hint(
    name = "CCryptoBoringSSL_interop",
    module_name = "CCryptoBoringSSL",
)

cc_library(
    name = "CCryptoBoringSSLShims",
    srcs = ["Sources/CCryptoBoringSSLShims/shims.c"],
    hdrs = ["Sources/CCryptoBoringSSLShims/include/CCryptoBoringSSLShims.h"],
    aspect_hints = [":CCryptoBoringSSLShims_interop"],
    includes = ["Sources/CCryptoBoringSSLShims/include"],
    deps = [":CCryptoBoringSSL"],
)

swift_interop_hint(
    name = "CCryptoBoringSSLShims_interop",
    module_name = "CCryptoBoringSSLShims",
)

swift_library(
    name = "CryptoBoringWrapper",
    srcs = glob(["Sources/CryptoBoringWrapper/**/*.swift"]),
    module_name = "CryptoBoringWrapper",
    deps = [
        ":CCryptoBoringSSL",
        ":CCryptoBoringSSLShims",
    ],
)
