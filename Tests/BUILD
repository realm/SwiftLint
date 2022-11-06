load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library", "swift_test")

exports_files(["BUILD"])

# CLITests

swift_library(
    name = "CLITests.library",
    testonly = True,
    srcs = glob(["CLITests/**/*.swift"]),
    module_name = "CLITests",
    deps = [
        "//:swiftlint.library",
    ],
)

swift_test(
    name = "CLITests",
    visibility = ["//visibility:public"],
    deps = [":CLITests.library"],
)

# SwiftLintTestHelpers

swift_library(
    name = "SwiftLintTestHelpers",
    testonly = True,
    srcs = glob(["SwiftLintTestHelpers/**/*.swift"]),
    module_name = "SwiftLintTestHelpers",
    deps = [
        "//:SwiftLintFramework",
    ],
)

# SwiftLintFrameworkTests

filegroup(
    name = "SwiftLintFrameworkTestsSources",
    srcs = glob(
        ["SwiftLintFrameworkTests/**/*.swift"],
        exclude = [
            "SwiftLintFrameworkTests/Resources/**",
            # Bazel doesn't support paths with spaces in them
            "SwiftLintFrameworkTests/FileNameNoSpaceRuleTests.swift",
        ],
    ),
)

filegroup(
    name = "SwiftLintFrameworkTestsData",
    srcs = glob(
        ["**/**"],
        # Bazel doesn't support paths with spaces in them
        exclude = ["SwiftLintFrameworkTests/Resources/FileNameNoSpaceRuleFixtures/**"],
    ),
    visibility = ["//visibility:public"],
)

swift_library(
    name = "SwiftLintFrameworkTests.library",
    testonly = True,
    srcs = [":SwiftLintFrameworkTestsSources"],
    module_name = "SwiftLintFrameworkTests",
    deps = [
        "//:SwiftLintFramework",
        ":SwiftLintTestHelpers",
    ],
)

swift_test(
    name = "SwiftLintFrameworkTests",
    data = glob(
        ["SwiftLintFrameworkTests/Resources/**"],
        # Bazel doesn't support paths with spaces in them
        exclude = ["SwiftLintFrameworkTests/Resources/FileNameNoSpaceRuleFixtures/**"],
    ),
    visibility = ["//visibility:public"],
    deps = [":SwiftLintFrameworkTests.library"],
)

# GeneratedTests

swift_library(
    name = "GeneratedTests.library",
    testonly = True,
    srcs = ["GeneratedTests/GeneratedTests.swift"],
    module_name = "GeneratedTests",
    deps = [
        "//:SwiftLintBuiltInRules",
        ":SwiftLintTestHelpers",
    ],
)

swift_test(
    name = "GeneratedTests",
    visibility = ["//visibility:public"],
    deps = [":GeneratedTests.library"],
)

# IntegrationTests

swift_library(
    name = "IntegrationTests.library",
    testonly = True,
    srcs = ["IntegrationTests/IntegrationTests.swift"],
    module_name = "IntegrationTests",
    deps = [
        "//:SwiftLintFramework",
        ":SwiftLintTestHelpers",
    ],
)

swift_test(
    name = "IntegrationTests",
    data = ["//:LintInputs"],
    visibility = ["//visibility:public"],
    deps = [":IntegrationTests.library"],
)

# ExtraRulesTests

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
        "ExtraRulesTests/ExtraRulesTests.swift",
    ] + select({
        "@platforms//os:linux": [":ExtraRulesLinuxMain"],
        "//conditions:default": [],
    }),
    module_name = "ExtraRulesTests",
    deps = [
        "//:SwiftLintFramework",
        ":SwiftLintTestHelpers",
    ],
)

swift_test(
    name = "ExtraRulesTests",
    visibility = ["//visibility:public"],
    deps = [
        ":ExtraRulesTests.library",
    ],
)
