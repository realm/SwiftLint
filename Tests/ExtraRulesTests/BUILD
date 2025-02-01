load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library", "swift_test")
load("//bazel:copts.bzl", "STRICT_COPTS")

filegroup(
    name = "TestSources",
    srcs = ["BUILD", "ExtraRulesTests.swift"],
    visibility = ["//visibility:public"],
)

swift_library(
    name = "ExtraRulesTests.library",
    package_name = "SwiftLint",
    testonly = True,
    srcs = [
        "ExtraRulesTests.swift",
    ],
    copts = STRICT_COPTS,
    module_name = "ExtraRulesTests",
    visibility = ["//visibility:public"],
    deps = [
        "//Tests/TestHelpers",
    ],
)

swift_test(
    name = "ExtraRulesTests",
    visibility = ["//visibility:public"],
    deps = [
        ":ExtraRulesTests.library",
    ],
)
