load("@build_bazel_rules_apple//apple:apple.bzl", "apple_universal_binary")
load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_binary",
    "swift_library",
    "swift_compiler_plugin"
)

copts = ["-enable-upcoming-feature", "ExistentialAny"]

# Targets

swift_library(
    name = "SwiftLintCoreMacrosLib",
    module_name = "SwiftLintCoreMacros",
    srcs = glob(["Source/SwiftLintCoreMacros/*.swift"]),
    visibility = ["//visibility:public"],
    deps = [
        "@SwiftSyntax//:SwiftCompilerPlugin_opt",
        "@SwiftSyntax//:SwiftSyntaxMacros_opt",
    ],
    copts = copts,
)

swift_compiler_plugin(
    name = "SwiftLintCoreMacros",
    srcs = glob(["Source/SwiftLintCoreMacros/*.swift"]),
    deps = [
        "@SwiftSyntax//:SwiftCompilerPlugin_opt",
        "@SwiftSyntax//:SwiftSyntaxMacros_opt",
    ],
    copts = copts,
)

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
    plugins = [
        ":SwiftLintCoreMacros",
    ],
    copts = copts,
)

swift_library(
    name = "SwiftLintBuiltInRules",
    srcs = glob(["Source/SwiftLintBuiltInRules/**/*.swift"]),
    module_name = "SwiftLintBuiltInRules",
    visibility = ["//visibility:public"],
    deps = [
        ":SwiftLintCore",
    ],
    copts = copts,
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
    copts = copts,
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
    copts = copts,
)

swift_binary(
    name = "swiftlint",
    visibility = ["//visibility:public"],
    deps = [
        ":swiftlint.library",
    ],
    copts = copts,
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
