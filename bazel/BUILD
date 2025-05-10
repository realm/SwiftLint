load(
    "@rules_xcodeproj//xcodeproj:defs.bzl",
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
                "//:swiftlint",
                args = [
                    "--progress",
                ],
            ),
            test_action = xcode_schemes.test_action([
                "//Tests:BuiltInRulesTests",
                "//Tests:CLITests",
                "//Tests:ExtraRulesTests",
                "//Tests:FrameworkTests",
                "//Tests:GeneratedTests",
                "//Tests:IntegrationTests",
                "//Tests:MacroTests",
            ]),
        ),
    ],
    top_level_targets = [
        "//:swiftlint",
        "//Tests:BuiltInRulesTests",
        "//Tests:CLITests",
        "//Tests:ExtraRulesTests",
        "//Tests:FrameworkTests",
        "//Tests:GeneratedTests",
        "//Tests:IntegrationTests",
        "//Tests:MacroTests",
    ],
)

# Release Files

filegroup(
    name = "release_files",
    srcs = glob(["*"]),
    visibility = ["//visibility:public"],
)
