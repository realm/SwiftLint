# GENERATED FILE. DO NOT EDIT!

"""Generated test targets for SwiftLint rules."""

load(":test_macros.bzl", "generated_test_shard")

def generated_tests():
    """Creates all generated test targets for SwiftLint rules."""
    generated_test_shard("01")
    generated_test_shard("02")
    generated_test_shard("03")
    generated_test_shard("04")
    generated_test_shard("05")
    generated_test_shard("06")
    generated_test_shard("07")
    generated_test_shard("08")
    generated_test_shard("09")
    generated_test_shard("10")

    native.test_suite(
        name = "GeneratedTests",
        tests = [
        "//Tests:GeneratedTests_01",
        "//Tests:GeneratedTests_02",
        "//Tests:GeneratedTests_03",
        "//Tests:GeneratedTests_04",
        "//Tests:GeneratedTests_05",
        "//Tests:GeneratedTests_06",
        "//Tests:GeneratedTests_07",
        "//Tests:GeneratedTests_08",
        "//Tests:GeneratedTests_09",
        "//Tests:GeneratedTests_10"
        ],
        visibility = ["//visibility:public"],
    )

GENERATED_TEST_TARGETS = [
        "//Tests:GeneratedTests_01",
        "//Tests:GeneratedTests_02",
        "//Tests:GeneratedTests_03",
        "//Tests:GeneratedTests_04",
        "//Tests:GeneratedTests_05",
        "//Tests:GeneratedTests_06",
        "//Tests:GeneratedTests_07",
        "//Tests:GeneratedTests_08",
        "//Tests:GeneratedTests_09",
        "//Tests:GeneratedTests_10"
]
