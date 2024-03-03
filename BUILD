load("@bazel_skylib//rules:common_settings.bzl", "bool_flag")
load("@build_bazel_rules_apple//apple:apple.bzl", "apple_universal_binary")
load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_binary",
    "swift_compiler_plugin",
    "swift_library",
    "universal_swift_compiler_plugin",
)

config_setting(
    name = "strict_concurrency_builtin_rules",
    values = {"define": "strict_concurrency_builtin_rules=true"},
)

bool_flag(
    name = "universal_tools",
    build_setting_default = False,
)

config_setting(
    name = "universal_tools_config",
    flag_values = {
        "@SwiftLint//:universal_tools": "true",
    },
)

copts = [
    "-enable-upcoming-feature",
    "ExistentialAny",
]

strict_concurrency_copts = [
    "-Xfrontend",
    "-strict-concurrency=complete",
]

# Targets

swift_library(
    name = "SwiftLintCoreMacrosLib",
    srcs = glob(["Source/SwiftLintCoreMacros/*.swift"]),
    copts = copts + strict_concurrency_copts,
    module_name = "SwiftLintCoreMacros",
    visibility = ["//visibility:public"],
    deps = [
        "@SwiftSyntax//:SwiftCompilerPlugin_opt",
        "@SwiftSyntax//:SwiftSyntaxMacros_opt",
    ],
)

swift_compiler_plugin(
    name = "SwiftLintCoreMacros.underlying",
    srcs = glob(["Source/SwiftLintCoreMacros/*.swift"]),
    copts = copts + strict_concurrency_copts,
    module_name = "SwiftLintCoreMacros",
    deps = [
        "@SwiftSyntax//:SwiftCompilerPlugin_opt",
        "@SwiftSyntax//:SwiftSyntaxMacros_opt",
    ],
)

universal_swift_compiler_plugin(
    name = "SwiftLintCoreMacros",
    plugin = "SwiftLintCoreMacros.underlying",
)

swift_library(
    name = "SwiftLintCore",
    package_name = "SwiftLint",
    srcs = glob(["Source/SwiftLintCore/**/*.swift"]),
    copts = copts,  # TODO: strict_concurrency_copts
    module_name = "SwiftLintCore",
    plugins = select({
        ":universal_tools_config": [":SwiftLintCoreMacros"],
        "//conditions:default": [":SwiftLintCoreMacros.underlying"],
    }),
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
    package_name = "SwiftLint",
    srcs = glob(["Source/SwiftLintBuiltInRules/**/*.swift"]),
    copts = copts + select({
        ":strict_concurrency_builtin_rules": strict_concurrency_copts,
        "//conditions:default": [],
    }),
    module_name = "SwiftLintBuiltInRules",
    visibility = ["//visibility:public"],
    deps = [
        ":SwiftLintCore",
    ],
)

swift_library(
    name = "SwiftLintExtraRules",
    package_name = "SwiftLint",
    srcs = [
        "Source/SwiftLintExtraRules/Exports.swift",
        "@swiftlint_extra_rules//:extra_rules",
    ],
    copts = copts + strict_concurrency_copts,
    module_name = "SwiftLintExtraRules",
    visibility = ["//visibility:public"],
    deps = [
        ":SwiftLintCore",
    ],
)

swift_library(
    name = "SwiftLintFramework",
    package_name = "SwiftLint",
    srcs = glob(
        ["Source/SwiftLintFramework/**/*.swift"],
    ),
    copts = copts + strict_concurrency_copts,
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
    package_name = "SwiftLint",
    srcs = glob(["Source/swiftlint/**/*.swift"]),
    copts = copts,  # TODO: strict_concurrency_copts
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
    copts = copts + strict_concurrency_copts,
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
