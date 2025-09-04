load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")
load("//bazel:copts.bzl", "STRICT_COPTS")

swift_library(
    name = "TestHelpers",
    package_name = "SwiftLint",
    testonly = True,
    srcs = glob(["**/*.swift"]),
    copts = STRICT_COPTS,
    module_name = "TestHelpers",
    visibility = ["//visibility:public"],
    deps = [
        "//:SwiftLintFramework",
    ],
)
