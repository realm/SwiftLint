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

# Targets

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

# Analyze

filegroup(
    name = "SourceAndTestFiles",
    srcs = glob([
        "Source/**",
        "Tests/SwiftLintFrameworkTests/**",
    ]),
)

sh_test(
    name = "analyze",
    srcs = ["script/test-analyze.sh"],
    data = [
        "Package.resolved",
        "Package.swift",
        ":LintInputs",
        ":SourceAndTestFiles",
        ":swiftlint",
    ],
)

# Danger

load("@bazelruby_rules_ruby//ruby:defs.bzl", "ruby_binary")

ruby_binary(
    name = "danger",
    main = "@bundle//:bin/danger",
    deps = ["@bundle//:bin"],
)

# Jazzy

ruby_binary(
    name = "jazzy",
    main = "@bundle//:bin/jazzy",
    deps = ["@bundle//:bin"],
)

genrule(
    name = "html_docs",
    srcs = [
        ":SourceAndTestFiles",
        "Package.swift",
        "Package.resolved",
    ],
    outs = ["docs"],
    cmd = """
set -euo pipefail

# Change to workspace directory
cd $$(dirname "$$(readlink "Package.swift")")
$(location swiftlint) generate-docs
$(location @com_github_jpsim_sourcekitten//:sourcekitten) \
  doc --spm --module-name SwiftLintFramework > SwiftLintFramework.json
$(location jazzy) --sourcekitten-sourcefile SwiftLintFramework.json --output $(OUTS)
    """,
    exec_tools = [
        "@com_github_jpsim_sourcekitten//:sourcekitten",
        "jazzy",
        "swiftlint",
    ],
)
