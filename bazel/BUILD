load(
    "@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:defs.bzl",
    "xcode_schemes",
    "xcodeproj",
)

# Xcode Integration

xcodeproj(
    name = "xcodeproj",
    install_directory = "",
    project_name = "SwiftLint",
    schemes = [
        xcode_schemes.scheme(
            name = "SwiftLint",
            launch_action = xcode_schemes.launch_action(
                target = "//:swiftlint",
                args = [
                    "--progress",
                ],
            ),
            test_action = xcode_schemes.test_action([
                "//Tests:CLITests",
                "//Tests:SwiftLintFrameworkTests",
                "//Tests:GeneratedTests",
                "//Tests:IntegrationTests",
                "//Tests:ExtraRulesTests",
            ]),
        ),
    ],
    top_level_targets = [
        "//:swiftlint",
        "//Tests:CLITests",
        "//Tests:SwiftLintFrameworkTests",
        "//Tests:GeneratedTests",
        "//Tests:IntegrationTests",
        "//Tests:ExtraRulesTests",
    ],
)

# Release Files

filegroup(
    name = "release_files",
    srcs = glob(["*"]),
    visibility = ["//visibility:public"],
)
