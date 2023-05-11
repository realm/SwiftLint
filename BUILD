load("@build_bazel_rules_apple//apple:apple.bzl", "apple_universal_binary")
load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_binary",
    "swift_library",
)
load(
    "@rules_xcodeproj//xcodeproj:defs.bzl",
    "xcode_schemes",
    "xcodeproj",
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

# Xcode Integration

xcodeproj(
    name = "xcodeproj",
    project_name = "SwiftLint",
    schemes = [
        xcode_schemes.scheme(
            name = "SwiftLint",
            launch_action = xcode_schemes.launch_action(
                "swiftlint",
                args = [
                    "--progress",
                ],
            ),
            test_action = xcode_schemes.test_action([
                "//Tests:CLITests",
                "//Tests:SwiftLintFrameworkTests",
                "//Tests:GeneratedTests",
                "//Tests:IntegrationTests",
                "//Tests:ExtraRulesTests",
            ]),
        ),
    ],
    top_level_targets = [
        "//:swiftlint",
        "//Tests:CLITests",
        "//Tests:SwiftLintFrameworkTests",
        "//Tests:GeneratedTests",
        "//Tests:IntegrationTests",
        "//Tests:ExtraRulesTests",
    ],
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
