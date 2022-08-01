load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_binary",
    "swift_library",
)
load("@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:xcodeproj.bzl", "xcodeproj")

swift_library(
    name = "SwiftLintFramework",
    srcs = glob(
        ["Source/SwiftLintFramework/**/*.swift"],
        exclude = ["Source/SwiftLintFramework/Rules/ExcludedFromBazel/ExtraRules.swift"],
    ) + ["@swiftlint_extra_rules//:extra_rules"],
    module_name = "SwiftLintFramework",
    visibility = ["//visibility:public"],
    deps = [
        "@com_github_jpsim_sourcekitten//:SourceKittenFramework",
        "@com_github_keith_swift_syntax//:SwiftSyntax",
        "@com_github_keith_swift_syntax//:SwiftSyntaxParser",
        "@sourcekitten_com_github_jpsim_yams//:Yams",
    ] + select({
        "@platforms//os:linux": ["@com_github_krzyzanowskim_cryptoswift//:CryptoSwift"],
        "//conditions:default": [],
    }),
)

swift_binary(
    name = "swiftlint",
    srcs = glob(["Source/swiftlint/**/*.swift"]),
    visibility = ["//visibility:public"],
    deps = [
        ":SwiftLintFramework",
        "@sourcekitten_com_github_apple_swift_argument_parser//:ArgumentParser",
        "@swiftlint_com_github_scottrhoyt_swifty_text_table//:SwiftyTextTable",
    ],
)

xcodeproj(
    name = "xcodeproj",
    build_mode = "bazel",
    project_name = "SwiftLint",
    tags = ["manual"],
    top_level_targets = [
        ":swiftlint",
        ":SwiftLintFramework",
        "//Tests:ExtraRulesTests",
    ],
)
