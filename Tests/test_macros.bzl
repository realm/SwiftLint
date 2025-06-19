load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library", "swift_test")

def generated_test_shard(shard_number, copts, strict_concurrency_copts):
    """Creates a single generated test shard with library and test targets.

    Args:
        shard_number: The shard number as a string
        copts: Common compiler options
        strict_concurrency_copts: Strict concurrency compiler options
    """
    swift_library(
        name = "GeneratedTests_{}.library".format(shard_number),
        testonly = True,
        srcs = ["GeneratedTests/GeneratedTests_{}.swift".format(shard_number)],
        module_name = "GeneratedTests_{}".format(shard_number),
        package_name = "SwiftLint",
        deps = [
            ":TestHelpers",
        ],
        copts = copts + strict_concurrency_copts,
    )

    swift_test(
        name = "GeneratedTests_{}".format(shard_number),
        visibility = ["//visibility:public"],
        deps = [":GeneratedTests_{}.library".format(shard_number)],
    )
