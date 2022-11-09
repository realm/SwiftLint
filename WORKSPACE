workspace(name = "SwiftLint")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "build_bazel_rules_apple",
    sha256 = "f94e6dddf74739ef5cb30f000e13a2a613f6ebfa5e63588305a71fce8a8a9911",
    url = "https://github.com/bazelbuild/rules_apple/releases/download/1.1.3/rules_apple.1.1.3.tar.gz",
)

load(
    "@build_bazel_rules_apple//apple:repositories.bzl",
    "apple_rules_dependencies",
)

apple_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:repositories.bzl",
    "swift_rules_dependencies",
)

swift_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:extras.bzl",
    "swift_rules_extra_dependencies",
)

swift_rules_extra_dependencies()

load("//bazel:repos.bzl", "swiftlint_repos")

swiftlint_repos()

load("//bazel:deps.bzl", "swiftlint_deps")

swiftlint_deps()

http_archive(
    name = "com_github_buildbuddy_io_rules_xcodeproj",
    sha256 = "2f9638b7bae45c0ba6f53a66788a0ec17db6455f4db4df6abaf07017ee9a9419",
    url = "https://github.com/buildbuddy-io/rules_xcodeproj/releases/download/0.10.0/release.tar.gz",
)

load("@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:repositories.bzl", "xcodeproj_rules_dependencies")

xcodeproj_rules_dependencies()

load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

git_repository(
    name = "bazelruby_rules_ruby",
    commit = "c93a6814b6193572c7c8b677b560314f52b31962",
    remote = "https://github.com/bazelruby/rules_ruby.git",
    shallow_since = "1651264604 -0700",
)

load(
    "@bazelruby_rules_ruby//ruby:deps.bzl",
    "rules_ruby_dependencies",
    "rules_ruby_select_sdk",
)

rules_ruby_dependencies()

load("@bazel_skylib//:workspace.bzl", "bazel_skylib_workspace")

bazel_skylib_workspace()

rules_ruby_select_sdk(version = "host")

load(
    "@bazelruby_rules_ruby//ruby:defs.bzl",
    "ruby_bundle",
)

ruby_bundle(
    name = "bundle",
    gemfile = "//:Gemfile",
    gemfile_lock = "//:Gemfile.lock",
)
