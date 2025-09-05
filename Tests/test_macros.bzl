"""Test macros for SwiftLint generated tests."""

load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library", "swift_test")
load("//bazel:copts.bzl", "STRICT_COPTS")

def generated_test_shard(shard_number):
    """Creates a single generated test shard with library and test targets.

    Args:
        shard_number: The shard number as a string
    """
    swift_library(
        name = "GeneratedTests_{}.library".format(shard_number),
        testonly = True,
        srcs = ["GeneratedTests/GeneratedTests_{}.swift".format(shard_number)],
        module_name = "GeneratedTests_{}".format(shard_number),
        package_name = "SwiftLint",
        deps = [
            "//Tests/TestHelpers",
        ],
        copts = STRICT_COPTS,
    )

    swift_test(
        name = "GeneratedTests_{}".format(shard_number),
        deps = [":GeneratedTests_{}.library".format(shard_number)],
    )
