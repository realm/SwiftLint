# GENERATED FILE. DO NOT EDIT!

load(":test_macros.bzl", "generated_test_shard")

def generated_tests(copts, strict_concurrency_copts):
    """Creates all generated test targets for SwiftLint rules.

    Args:
        copts: Common compiler options
        strict_concurrency_copts: Strict concurrency compiler options
    """
    generated_test_shard("01", copts, strict_concurrency_copts)
    generated_test_shard("02", copts, strict_concurrency_copts)
    generated_test_shard("03", copts, strict_concurrency_copts)
    generated_test_shard("04", copts, strict_concurrency_copts)
    generated_test_shard("05", copts, strict_concurrency_copts)
    generated_test_shard("06", copts, strict_concurrency_copts)
    generated_test_shard("07", copts, strict_concurrency_copts)
    generated_test_shard("08", copts, strict_concurrency_copts)
    generated_test_shard("09", copts, strict_concurrency_copts)
    generated_test_shard("10", copts, strict_concurrency_copts)
