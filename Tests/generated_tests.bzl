# GENERATED FILE. DO NOT EDIT!

load("@build_bazel_rules_swift//swift:swift.bzl", "swift_library", "swift_test")

def _generated_test_shard(shard_number, copts, strict_concurrency_copts):
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

def generated_tests(copts, strict_concurrency_copts):
    """Creates all generated test targets for SwiftLint rules.

    Args:
        copts: Common compiler options
        strict_concurrency_copts: Strict concurrency compiler options
    """
    _generated_test_shard("01", copts, strict_concurrency_copts)
    _generated_test_shard("02", copts, strict_concurrency_copts)
    _generated_test_shard("03", copts, strict_concurrency_copts)
    _generated_test_shard("04", copts, strict_concurrency_copts)
    _generated_test_shard("05", copts, strict_concurrency_copts)
    _generated_test_shard("06", copts, strict_concurrency_copts)
    _generated_test_shard("07", copts, strict_concurrency_copts)
    _generated_test_shard("08", copts, strict_concurrency_copts)
    _generated_test_shard("09", copts, strict_concurrency_copts)
    _generated_test_shard("10", copts, strict_concurrency_copts)
