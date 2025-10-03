load(
    "@rules_xcodeproj//xcodeproj:defs.bzl",
    "xcode_schemes",
    "xcodeproj",
)

# Xcode Integration

TEST_TARGETS = [
    "//Tests:BuiltInRulesTests",
    "//Tests:CoreTests",
    "//Tests/ExtraRulesTests:ExtraRulesTests",
    "//Tests:FileSystemAccessTests",
    "//Tests:FrameworkTests",
    "//Tests:GeneratedTests",
    "//Tests:IntegrationTests",
    "//Tests:MacroTests",
]

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
            test_action = xcode_schemes.test_action(TEST_TARGETS),
        ),
    ],
    top_level_targets = ["//:swiftlint"] + TEST_TARGETS,
)

# Release Files

filegroup(
    name = "release_files",
    srcs = glob(["*"]),
    visibility = ["//visibility:public"],
)
