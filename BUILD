load("@bazel_skylib//rules:common_settings.bzl", "bool_flag")
load("@build_bazel_rules_apple//apple:apple.bzl", "apple_universal_binary")
load("@build_bazel_rules_shell//shell:sh_test.bzl", "sh_test")
load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_binary",
    "swift_compiler_plugin",
    "swift_library",
    "universal_swift_compiler_plugin",
)
load("@rules_cc//cc:cc_library.bzl", "cc_library")
load("//bazel:copts.bzl", "STRICT_COPTS", "TARGETED_COPTS")

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

# Targets

swift_library(
    name = "SwiftLintCoreMacrosLib",
    srcs = glob(
        ["Source/SwiftLintCoreMacros/*.swift"],
        # Contains the `@main` declaration which causes linker errors if used as a library in tests.
        exclude = ["Source/SwiftLintCoreMacros/SwiftLintCoreMacros.swift"]
    ),
    copts = STRICT_COPTS,
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
    copts = STRICT_COPTS,
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
    copts = STRICT_COPTS,
    module_name = "SwiftLintCore",
    plugins = select({
        ":universal_tools_config": [":SwiftLintCoreMacros"],
        "//conditions:default": [":SwiftLintCoreMacros.underlying"],
    }),
    visibility = ["//visibility:public"],
    deps = [
        ":Yams.wrapper",
        "@FilenameMatcher",
        "@SourceKittenFramework",
        "@SwiftSyntax//:SwiftIDEUtils_opt",
        "@SwiftSyntax//:SwiftOperators_opt",
        "@SwiftSyntax//:SwiftParserDiagnostics_opt",
        "@SwiftSyntax//:SwiftSyntaxBuilder_opt",
        "@SwiftSyntax//:SwiftSyntax_opt",
        "@SwiftyTextTable",
    ] + select({
        "@platforms//os:linux": ["@CryptoSwift"],
        "//conditions:default": [":DyldWarningWorkaround"],
    }),
)

swift_library(
    name = "Yams.wrapper",
    srcs = ["Source/YamsWrapper/Empty.swift"],
    module_name = "YamsWrapper",
    deps = [
        "@Yams",
    ],
)

swift_library(
    name = "SwiftLintBuiltInRules",
    package_name = "SwiftLint",
    srcs = glob(["Source/SwiftLintBuiltInRules/**/*.swift"]),
    copts = STRICT_COPTS,
    module_name = "SwiftLintBuiltInRules",
    visibility = ["//visibility:public"],
    deps = [
        ":SwiftLintCore",
        "@SwiftSyntax//:SwiftLexicalLookup_opt",
    ],
)

swift_library(
    name = "SwiftLintExtraRules",
    package_name = "SwiftLint",
    srcs = [
        "Source/SwiftLintExtraRules/Exports.swift",
        "@swiftlint_extra_rules//:extra_rules",
    ],
    copts = STRICT_COPTS,
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
    copts = TARGETED_COPTS,
    module_name = "SwiftLintFramework",
    visibility = ["//visibility:public"],
    deps = [
        ":SwiftLintBuiltInRules",
        ":SwiftLintCore",
        ":SwiftLintExtraRules",
        "@CollectionConcurrencyKit",
    ],
)

swift_binary(
    name = "swiftlint",
    package_name = "SwiftLint",
    srcs = glob(["Source/swiftlint/**/*.swift"]),
    copts = STRICT_COPTS,
    visibility = ["//visibility:public"],
    deps = [
        ":SwiftLintFramework",
        "@SwiftArgumentParser//:ArgumentParser",
        "@SwiftyTextTable",
    ],
)

swift_binary(
    name = "swiftlint-dev",
    package_name = "SwiftLint",
    srcs = glob(["Source/swiftlint-dev/*.swift"]),
    copts = STRICT_COPTS,
    visibility = ["//visibility:public"],
    deps = [
        ":SwiftLintFramework",
        "@SwiftArgumentParser//:ArgumentParser",
    ],
)

apple_universal_binary(
    name = "universal_swiftlint",
    binary = ":swiftlint",
    forced_cpus = [
        "x86_64",
        "arm64",
    ],
    minimum_os_version = "13.0",
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
    name = "SourceFiles",
    srcs = glob([
        "Source/**/*.swift",
    ]),
    visibility = ["//Tests:__subpackages__"],
)

filegroup(
    name = "LintInputs",
    srcs = glob(
        ["Plugins/**/*.swift"],
        allow_empty = True
    ) + [
        ":SourceFiles",
        ".swiftlint.yml",
        "Package.swift",
        "//Tests:TestSources",
    ],
    visibility = ["//Tests:__subpackages__"],
)

# Release

filegroup(
    name = "release_files",
    srcs = [
        ":SourceFiles",
        "BUILD",
        "LICENSE",
        "MODULE.bazel",
        "//:DyldWarningWorkaroundSources",
        "//Tests/ExtraRulesTests:TestSources",
        "//Tests/TestHelpers:TestSources",
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
