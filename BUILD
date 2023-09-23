load("@build_bazel_rules_apple//apple:apple.bzl", "apple_universal_binary")
load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_binary",
    "swift_library",
)

# Targets

swift_library(
    name = "SwiftLintCore",
    srcs = glob(["Source/SwiftLintCore/**/*.swift"]),
    module_name = "SwiftLintCore",
    visibility = ["//visibility:public"],
    deps = [
        "@SwiftSyntax//:SwiftIDEUtils_opt",
        "@SwiftSyntax//:SwiftOperators_opt",
        "@SwiftSyntax//:SwiftParserDiagnostics_opt",
        "@SwiftSyntax//:SwiftSyntaxBuilder_opt",
        "@SwiftSyntax//:SwiftSyntax_opt",
        "@com_github_jpsim_sourcekitten//:SourceKittenFramework",
        "@sourcekitten_com_github_jpsim_yams//:Yams",
        "@swiftlint_com_github_scottrhoyt_swifty_text_table//:SwiftyTextTable",
    ] + select({
        "@platforms//os:linux": ["@com_github_krzyzanowskim_cryptoswift//:CryptoSwift"],
        "//conditions:default": [":DyldWarningWorkaround"],
    }),
)

swift_library(
    name = "SwiftLintBuiltInRules",
    srcs = glob(["Source/SwiftLintBuiltInRules/**/*.swift"]),
    module_name = "SwiftLintBuiltInRules",
    visibility = ["//visibility:public"],
    deps = [
        ":SwiftLintCore",
    ],
)

swift_library(
    name = "SwiftLintExtraRules",
    srcs = [
        "Source/SwiftLintExtraRules/Exports.swift",
        "@swiftlint_extra_rules//:extra_rules",
    ],
    module_name = "SwiftLintExtraRules",
    visibility = ["//visibility:public"],
    deps = [
        ":SwiftLintCore",
    ],
)

swift_library(
    name = "SwiftLintFramework",
    srcs = glob(
        ["Source/SwiftLintFramework/**/*.swift"],
    ),
    module_name = "SwiftLintFramework",
    visibility = ["//visibility:public"],
    deps = [
        ":SwiftLintBuiltInRules",
        ":SwiftLintCore",
        ":SwiftLintExtraRules",
    ],
)

swift_library(
    name = "swiftlint.library",
    srcs = glob(["Source/swiftlint/**/*.swift"]),
    module_name = "swiftlint",
    visibility = ["//visibility:public"],
    deps = [
        ":SwiftLintFramework",
        "@com_github_johnsundell_collectionconcurrencykit//:CollectionConcurrencyKit",
        "@sourcekitten_com_github_apple_swift_argument_parser//:ArgumentParser",
        "@swiftlint_com_github_scottrhoyt_swifty_text_table//:SwiftyTextTable",
    ],
)

swift_binary(
    name = "swiftlint",
    visibility = ["//visibility:public"],
    deps = [
        ":swiftlint.library",
    ],
)

apple_universal_binary(
    name = "universal_swiftlint",
    binary = ":swiftlint",
    forced_cpus = [
        "x86_64",
        "arm64",
    ],
    minimum_os_version = "12.0",
    platform_type = "macos",
    visibility = ["//visibility:public"],
)

filegroup(
    name = "DyldWarningWorkaroundSources",
    srcs = [
        "Source/DyldWarningWorkaround/DyldWarningWorkaround.c",
        "Source/DyldWarningWorkaround/include/objc_dupclass.h",
    ],
)

cc_library(
    name = "DyldWarningWorkaround",
    srcs = ["//:DyldWarningWorkaroundSources"],
    includes = ["Source/DyldWarningWorkaround/include"],
    alwayslink = True,
)

# Linting

filegroup(
    name = "LintInputs",
    srcs = glob(["Source/**/*.swift"]) + [
        ".swiftlint.yml",
        "//Tests:SwiftLintFrameworkTestsData",
    ],
    visibility = ["//Tests:__subpackages__"],
)

# Release

filegroup(
    name = "release_files",
    srcs = [
        "BUILD",
        "LICENSE",
        "MODULE.bazel",
        "//:DyldWarningWorkaroundSources",
        "//:LintInputs",
        "//Tests:BUILD",
        "//bazel:release_files",
    ],
)

# TODO: Use rules_pkg
genrule(
    name = "release",
    srcs = [":release_files"],
    outs = [
        "bazel.tar.gz",
        "bazel.tar.gz.sha256",
    ],
    cmd = """\
set -euo pipefail

outs=($(OUTS))

COPYFILE_DISABLE=1 tar czvfh "$${outs[0]}" \
  --exclude ^bazel-out/ \
  --exclude ^external/ \
  *
shasum -a 256 "$${outs[0]}" > "$${outs[1]}"
    """,
)

# Analyze

sh_test(
    name = "analyze",
    srcs = ["//tools:test-analyze.sh"],
    data = [
        "Package.resolved",
        "Package.swift",
        ":LintInputs",
        ":swiftlint",
    ],
)

# Xcode versions

xcode_version(
    name = 'version15_0_0_15A240d',
    version = '15.0.0.15A240d',
    aliases = ['15A240d', '15.0.0.15A240d', '15.0', '15.0.0', '15'],
    default_ios_sdk_version = '17.0',
    default_tvos_sdk_version = '17.0',
    default_macos_sdk_version = '14.0',
    default_watchos_sdk_version = '10.0',
)

available_xcodes(
    name = 'fixed_xcode',
    versions = [':version15_0_0_15A240d'],
    default = ':version15_0_0_15A240d',
)

xcode_config(
    name = "xcode_config",
    local_versions = ":fixed_xcode",
    remote_versions = ":fixed_xcode",
)
