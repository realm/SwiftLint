load(
    "@build_bazel_rules_swift//swift:swift.bzl",
    "swift_library",
)

swift_library(
    name = "CryptoSwift",
    srcs = glob(["Sources/**/*.swift"]),
    features = [
        "swift.enable_library_evolution",
    ],
    module_name = "CryptoSwift",
    visibility = ["//visibility:public"],
)
