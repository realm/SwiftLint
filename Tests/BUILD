load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library", "swift_test")

exports_files(["BUILD"])

copts = [
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

# CLITests

swift_library(
    name = "CLITests.library",
    testonly = True,
    srcs = glob(["CLITests/**/*.swift"]),
    module_name = "CLITests",
    package_name = "SwiftLint",
    deps = [
        "//:SwiftLintFramework",
    ],
    copts = copts,
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
    module_name = "MacroTests",
    deps = [
        "//:SwiftLintCoreMacrosLib",
        "@SwiftSyntax//:SwiftSyntaxMacrosTestSupport_opt",
    ],
    copts = copts,
)

swift_test(
    name = "MacroTests",
    visibility = ["//visibility:public"],
    deps = [":MacroTests.library"],
)

# TestHelpers

swift_library(
    name = "TestHelpers",
    testonly = True,
    srcs = glob(["TestHelpers/**/*.swift"]),
    module_name = "TestHelpers",
    package_name = "SwiftLint",
    deps = [
        "//:SwiftLintFramework",
    ],
    copts = copts,
)

# BuiltInRulesTests

swift_library(
    name = "BuiltInRulesTests.library",
    testonly = True,
    srcs = glob(
        ["BuiltInRulesTests/**/*.swift"],
        exclude = [
            "BuiltInRulesTests/Resources/**",
            # Bazel doesn't support paths with spaces in them
            "BuiltInRulesTests/FileNameNoSpaceRuleTests.swift",
        ],
    ),
    module_name = "BuiltInRulesTests",
    package_name = "SwiftLint",
    deps = [
        ":TestHelpers",
    ],
    copts = copts,
)

swift_test(
    name = "BuiltInRulesTests",
    data = glob(
        ["BuiltInRulesTests/Resources/**"],
        # Bazel doesn't support paths with spaces in them
        exclude = ["BuiltInRulesTests/Resources/FileNameNoSpaceRuleFixtures/**"],
    ),
    visibility = ["//visibility:public"],
    deps = [":BuiltInRulesTests.library"],
)

# FrameworkTests

swift_library(
    name = "FrameworkTests.library",
    testonly = True,
    srcs = glob(
        ["FrameworkTests/**/*.swift"],
        exclude = [
            "FrameworkTests/Resources/**",
        ],
    ),
    module_name = "FrameworkTests",
    package_name = "SwiftLint",
    deps = [
        ":TestHelpers",
    ],
    copts = copts,
)

swift_test(
    name = "FrameworkTests",
    data = glob(
        ["FrameworkTests/Resources/**"],
    ),
    visibility = ["//visibility:public"],
    deps = [":FrameworkTests.library"],
)

# GeneratedTests

swift_library(
    name = "GeneratedTests.library",
    testonly = True,
    srcs = ["GeneratedTests/GeneratedTests.swift"],
    module_name = "GeneratedTests",
    package_name = "SwiftLint",
    deps = [
        ":TestHelpers",
    ],
    copts = copts,
)

swift_test(
    name = "GeneratedTests",
    visibility = ["//visibility:public"],
    deps = [":GeneratedTests.library"],
)

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
    testonly = True,
    srcs = ["IntegrationTests/IntegrationTests.swift"],
    module_name = "IntegrationTests",
    package_name = "SwiftLint",
    deps = [
        ":TestHelpers",
    ],
    copts = copts,
)

swift_test(
    name = "IntegrationTests",
    data = [
        "//:LintInputs",
        "IntegrationTests/default_rule_configurations.yml"
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
    testonly = True,
    srcs = [
        "ExtraRulesTests/ExtraRulesTests.swift",
    ] + select({
        "@platforms//os:linux": [":ExtraRulesLinuxMain"],
        "//conditions:default": [],
    }),
    module_name = "ExtraRulesTests",
    package_name = "SwiftLint",
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
