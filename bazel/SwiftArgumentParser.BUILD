load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library")

swift_library(
    name = "ArgumentParserToolInfo",
    srcs = glob(["Sources/ArgumentParserToolInfo/**/*.swift"]),
    module_name = "ArgumentParserToolInfo",
)

swift_library(
    name = "ArgumentParser",
    srcs = glob(["Sources/ArgumentParser/**/*.swift"]),
    module_name = "ArgumentParser",
    visibility = ["//visibility:public"],
    deps = [
        ":ArgumentParserToolInfo",
    ],
)
