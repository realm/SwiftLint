load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_binary",
    "swift_library",
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
        "@sourcekitten_com_github_apple_swift_argument_parser//:ArgumentParser",
        "@com_github_johnsundell_collectionconcurrencykit//:CollectionConcurrencyKit",
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

filegroup(
    name = "SourceAndTestFiles",
    srcs = glob(["Source/**", "Tests/SwiftLintFrameworkTests/**"]),
)

genrule(
    name = "write_swiftpm_yaml",
    srcs = [":SourceAndTestFiles", "Package.swift", "Package.resolved"],
    outs = ["swiftpm.yaml"],
    cmd = """
set -euo pipefail

swift package clean
swift build -c release
cp .build/release.yaml $(OUTS)
    """,
)

sh_test(
    name = "analyze",
    srcs = ["script/test-analyze.sh"],
    data = [":swiftlint", ":SwiftLintConfig", ":SourceAndTestFiles", "swiftpm.yaml"],
)
