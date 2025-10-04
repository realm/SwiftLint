load(
    "@rules_xcodeproj//xcodeproj:defs.bzl",
    "xcschemes",
    "xcodeproj",
)

load("//Tests:generated_tests.bzl", "GENERATED_TEST_TARGETS")

# Xcode Integration

TEST_TARGETS = [
    "//Tests:BuiltInRulesTests",
    "//Tests:CoreTests",
    "//Tests/ExtraRulesTests:ExtraRulesTests",
    "//Tests:FileSystemAccessTests",
    "//Tests:FrameworkTests",
    "//Tests:IntegrationTests",
    "//Tests:MacroTests",
] + GENERATED_TEST_TARGETS

xcodeproj(
    name = "xcodeproj",
    install_directory = "",
    project_name = "SwiftLint",
    xcschemes = [
        xcschemes.scheme(
            name = "SwiftLint",
            run = xcschemes.run(
                launch_target = xcschemes.launch_target(
                    "//:swiftlint",
                ),
                args = [
                    xcschemes.arg("--progress"),
                ],
            ),
            test = xcschemes.test(
                test_targets = TEST_TARGETS,
            ),
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
