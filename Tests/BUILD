load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library", "swift_test")

swift_library(
    name = "SwiftLintFrameworkTests.library",
    testonly = True,
    srcs = glob(
        ["SwiftLintFrameworkTests/**/*.swift"],
        exclude = [
            "SwiftLintFrameworkTests/Resources/**",
            # Bazel doesn't support paths with spaces in them
            "SwiftLintFrameworkTests/FileNameNoSpaceRuleTests.swift",
        ],
    ),
    module_name = "SwiftLintFrameworkTests",
    deps = [
        "//:SwiftLintFramework",
    ],
)

swift_test(
    name = "SwiftLintFrameworkTests",
    data = [
        "//:SwiftLintConfig",
        "//:SourceFilesToLint",
    ] + glob(
        ["SwiftLintFrameworkTests/**"],
        # Bazel doesn't support paths with spaces in them
        exclude = ["SwiftLintFrameworkTests/Resources/FileNameNoSpaceRuleFixtures/**"],
    ),
    visibility = ["//Tests:__subpackages__"],
    deps = [":SwiftLintFrameworkTests.library"],
)

genrule(
    name = "ExtraRulesLinuxMain",
    outs = ["main.swift"],
    cmd = """
echo "import XCTest

XCTMain([testCase(ExtraRulesTests.allTests)])" >> $(OUTS)
""",
)

swift_library(
    name = "ExtraRulesTests.library",
    testonly = True,
    srcs = [
        "SwiftLintFrameworkTests/ExtraRulesTests.swift",
        "SwiftLintFrameworkTests/TestHelpers.swift",
    ] + select({
        "@platforms//os:linux": [":ExtraRulesLinuxMain"],
        "//conditions:default": [],
    }),
    module_name = "ExtraRulesTests",
    deps = [
        "//:SwiftLintFramework",
    ],
)

swift_test(
    name = "ExtraRulesTests",
    visibility = ["//visibility:public"],
    deps = [
        ":ExtraRulesTests.library",
    ],
)
