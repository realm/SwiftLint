load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
load("@com_github_keith_swift_syntax_bazel//:deps.bzl", "swift_syntax_deps")
load("@com_github_jpsim_sourcekitten//bazel:repos.bzl", "sourcekitten_repos")

def swiftlint_deps():
    """Fetches SwiftLint dependencies"""
    if not native.existing_rule("build_bazel_rules_apple"):
        fail("error: this depends on rules_apple but that wasn't setup")

    if not native.existing_rule("build_bazel_rules_swift"):
        fail("error: this depends on rules_swift but that wasn't setup")

    swift_syntax_deps()
    sourcekitten_repos()
