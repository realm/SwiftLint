load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_binary",
    "swift_library",
)
load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:xcodeproj.bzl",
    "xcode_schemes",
    "xcodeproj",
)

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
        "@com_github_johnsundell_collectionconcurrencykit//:CollectionConcurrencyKit",
        "@sourcekitten_com_github_apple_swift_argument_parser//:ArgumentParser",
        "@swiftlint_com_github_scottrhoyt_swifty_text_table//:SwiftyTextTable",
    ],
)

filegroup(
    name = "SwiftLintConfig",
    srcs = [".swiftlint.yml"],
    visibility = ["//Tests:__subpackages__"],
)

filegroup(
    name = "SourceFilesToLint",
    srcs = glob(["Source/**"]),
    visibility = ["//Tests:__subpackages__"],
)

xcodeproj(
    name = "xcodeproj",
    build_mode = "bazel",
    project_name = "SwiftLint",
    schemes = [
        xcode_schemes.scheme(
            name = "SwiftLint",
            launch_action = xcode_schemes.launch_action("//:swiftlint"),
            test_action = xcode_schemes.test_action([
                "//Tests:SwiftLintFrameworkTests",
                "//Tests:ExtraRulesTests",
            ]),
        ),
    ],
    top_level_targets = [
        "//:swiftlint",
        "//Tests:SwiftLintFrameworkTests",
        "//Tests:ExtraRulesTests",
    ],
)
