load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library", "swift_test")
load(":generated_tests.bzl", "generated_tests")

exports_files(["BUILD"])

copts = [
    "-warnings-as-errors",
    "-enable-upcoming-feature",
    "ExistentialAny",
    "-enable-upcoming-feature",
    "ConciseMagicFile",
    "-enable-upcoming-feature",
    "ImportObjcForwardDeclarations",
    "-enable-upcoming-feature",
    "ForwardTrailingClosures",
    "-enable-upcoming-feature",
    "ImplicitOpenExistentials",
]

strict_concurrency_copts = [
    "-Xfrontend",
    "-strict-concurrency=complete",
]

targeted_concurrency_copts = [
    "-Xfrontend",
    "-strict-concurrency=targeted",
]

# CLITests

swift_library(
    name = "CLITests.library",
    package_name = "SwiftLint",
    testonly = True,
    srcs = glob(["CLITests/**/*.swift"]),
    copts = copts + strict_concurrency_copts,
    module_name = "CLITests",
    deps = [
        "//:SwiftLintFramework",
    ],
)

swift_test(
    name = "CLITests",
    visibility = ["//visibility:public"],
    deps = [":CLITests.library"],
)

# MacroTests

swift_library(
    name = "MacroTests.library",
    testonly = True,
    srcs = glob(["MacroTests/**/*.swift"]),
    copts = copts + strict_concurrency_copts,
    module_name = "MacroTests",
    deps = [
        "//:SwiftLintCoreMacrosLib",
        "@SwiftSyntax//:SwiftSyntaxMacrosTestSupport_opt",
    ],
)

swift_test(
    name = "MacroTests",
    visibility = ["//visibility:public"],
    deps = [":MacroTests.library"],
)

# TestHelpers

swift_library(
    name = "TestHelpers",
    package_name = "SwiftLint",
    testonly = True,
    srcs = glob(["TestHelpers/**/*.swift"]),
    copts = copts + strict_concurrency_copts,
    module_name = "TestHelpers",
    deps = [
        "//:SwiftLintFramework",
    ],
)

# BuiltInRulesTests

swift_library(
    name = "BuiltInRulesTests.library",
    package_name = "SwiftLint",
    testonly = True,
    srcs = glob(
        ["BuiltInRulesTests/**/*.swift"],
        exclude = [
            "BuiltInRulesTests/Resources/**",
            # Bazel doesn't support paths with spaces in them
            "BuiltInRulesTests/FileNameNoSpaceRuleTests.swift",
        ],
    ),
    copts = copts + strict_concurrency_copts,
    module_name = "BuiltInRulesTests",
    deps = [
        ":TestHelpers",
    ],
)

swift_test(
    name = "BuiltInRulesTests",
    data = glob(
        ["BuiltInRulesTests/Resources/**"],
        allow_empty = True,
        # Bazel doesn't support paths with spaces in them
        exclude = ["BuiltInRulesTests/Resources/FileNameNoSpaceRuleFixtures/**"],
    ),
    visibility = ["//visibility:public"],
    deps = [":BuiltInRulesTests.library"],
)

# FrameworkTests

swift_library(
    name = "FrameworkTests.library",
    package_name = "SwiftLint",
    testonly = True,
    srcs = glob(
        ["FrameworkTests/**/*.swift"],
        exclude = [
            "FrameworkTests/Resources/**",
        ],
    ),
    copts = copts + strict_concurrency_copts,
    module_name = "FrameworkTests",
    deps = [
        ":TestHelpers",
    ],
)

swift_test(
    name = "FrameworkTests",
    data = glob(
        ["FrameworkTests/Resources/**"],
        allow_empty = True,
    ),
    visibility = ["//visibility:public"],
    deps = [":FrameworkTests.library"],
)

# GeneratedTests

generated_tests(copts, strict_concurrency_copts)

# IntegrationTests

filegroup(
    name = "TestSources",
    srcs = glob(
        ["**/*.swift"],
        exclude = ["**/Resources/**"],
    ),
    visibility = ["//visibility:public"],
)

swift_library(
    name = "IntegrationTests.library",
    package_name = "SwiftLint",
    testonly = True,
    srcs = ["IntegrationTests/IntegrationTests.swift"],
    copts = copts + targeted_concurrency_copts,  # Set to strict once SwiftLintFramework is updated
    module_name = "IntegrationTests",
    deps = [
        ":TestHelpers",
    ],
)

swift_test(
    name = "IntegrationTests",
    data = [
        "IntegrationTests/default_rule_configurations.yml",
        "//:LintInputs",
    ],
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
    package_name = "SwiftLint",
    testonly = True,
    srcs = [
        "ExtraRulesTests/ExtraRulesTests.swift",
    ] + select({
        "@platforms//os:linux": [":ExtraRulesLinuxMain"],
        "//conditions:default": [],
    }),
    copts = copts + strict_concurrency_copts,
    module_name = "ExtraRulesTests",
    deps = [
        ":TestHelpers",
    ],
)

swift_test(
    name = "ExtraRulesTests",
    visibility = ["//visibility:public"],
    deps = [
        ":ExtraRulesTests.library",
    ],
)
