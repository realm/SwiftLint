load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@com_github_jpsim_sourcekitten//bazel:repos.bzl", "sourcekitten_repos")

def _extra_swift_sources_impl(ctx):
    ctx.file("WORKSPACE", "")
    ctx.file("empty.swift", "func extraRules() -> [Rule.Type] { [] }")
    label = ":empty"
    if ctx.attr.srcs:
        label = ctx.attr.srcs
    ctx.file("BUILD.bazel", """
filegroup(
    name = "empty",
    srcs = ["empty.swift"],
)

alias(
    name = "extra_rules",
    actual = "{}",
    visibility = ["//visibility:public"],
)""".format(label))

extra_swift_sources = repository_rule(
    implementation = _extra_swift_sources_impl,
    attrs = {
        "srcs": attr.label(allow_files = [".swift"]),
    },
)

def swiftlint_deps():
    """Fetches SwiftLint dependencies"""
    if not native.existing_rule("build_bazel_rules_apple"):
        fail("error: this depends on rules_apple but that wasn't setup")

    if not native.existing_rule("build_bazel_rules_swift"):
        fail("error: this depends on rules_swift but that wasn't setup")

    if not native.existing_rule("swiftlint_extra_rules"):
        extra_swift_sources(name = "swiftlint_extra_rules")

    sourcekitten_repos()
