load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library", "swift_test")
load("//bazel:copts.bzl", "STRICT_COPTS", "TARGETED_COPTS")
load(":generated_tests.bzl", "generated_tests")

# FileSystemAccessTests

swift_library(
    name = "FileSystemAccessTests.library",
    package_name = "SwiftLint",
    testonly = True,
    srcs = glob(["FileSystemAccessTests/*.swift"], exclude = ["FileSystemAccessTests/Resources/**"]),
    copts = STRICT_COPTS,
    module_name = "FileSystemAccessTests",
    deps = [
        "//:SwiftLintFramework",
        "//Tests/TestHelpers",
    ],
)

swift_test(
    name = "FileSystemAccessTests",
    data = glob(["FileSystemAccessTests/Resources/**"], allow_empty = True),
    deps = [":FileSystemAccessTests.library"],
    visibility = ["//visibility:public"],
)

# MacroTests

swift_library(
    name = "MacroTests.library",
    testonly = True,
    srcs = glob(["MacroTests/**/*.swift"]),
    copts = STRICT_COPTS,
    module_name = "MacroTests",
    deps = [
        "//:SwiftLintCoreMacrosLib",
        "//Tests/TestHelpers",
        "@SwiftSyntax//:SwiftSyntaxMacrosTestSupport_opt",
    ],
)

swift_test(
    name = "MacroTests",
    deps = [":MacroTests.library"],
    visibility = ["//visibility:public"],
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
    copts = STRICT_COPTS,
    module_name = "BuiltInRulesTests",
    deps = [
        "//Tests/TestHelpers",
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
    deps = [":BuiltInRulesTests.library"],
    visibility = ["//visibility:public"],
)

# CoreTests

swift_library(
    name = "CoreTests.library",
    package_name = "SwiftLint",
    testonly = True,
    srcs = glob(
        ["CoreTests/**/*.swift"],
        exclude = [
            "CoreTests/Resources/**",
        ],
    ),
    copts = STRICT_COPTS,
    module_name = "CoreTests",
    deps = [
        "//Tests/TestHelpers",
    ],
)

swift_test(
    name = "CoreTests",
    data = glob(
        ["CoreTests/Resources/**"],
        allow_empty = True,
    ),
    deps = [":CoreTests.library"],
    visibility = ["//visibility:public"],
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
    copts = STRICT_COPTS,
    module_name = "FrameworkTests",
    deps = [
        "//Tests/TestHelpers",
    ],
)

swift_test(
    name = "FrameworkTests",
    data = glob(
        ["FrameworkTests/Resources/**"],
        allow_empty = True,
    ),
    deps = [":FrameworkTests.library"],
    visibility = ["//visibility:public"],
)

# GeneratedTests

generated_tests()

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
    copts = TARGETED_COPTS,  # Set to strict once SwiftLintFramework is updated
    module_name = "IntegrationTests",
    deps = [
        "//Tests/TestHelpers",
    ],
)

swift_test(
    name = "IntegrationTests",
    data = [
        "IntegrationTests/Resources/default_rule_configurations.yml",
        "//:LintInputs",
    ],
    visibility = ["//visibility:public"],
    deps = [":IntegrationTests.library"],
)
