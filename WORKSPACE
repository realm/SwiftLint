workspace(name = "SwiftLint")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "build_bazel_rules_apple",
    sha256 = "f003875c248544009c8e8ae03906bbdacb970bc3e5931b40cd76cadeded99632",
    url = "https://github.com/bazelbuild/rules_apple/releases/download/1.1.0/rules_apple.1.1.0.tar.gz",
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
    sha256 = "1bfc8589398afc31c47c3cb402f848c89ea11f8992c3f1c8e93efafa23619a7f",
    # https://github.com/buildbuddy-io/rules_xcodeproj/pull/900
    strip_prefix = "rules_xcodeproj-da3c32c91653cd98d4cb0bb7ffe9ac81a6f5f800",
    url = "https://github.com/buildbuddy-io/rules_xcodeproj/archive/da3c32c91653cd98d4cb0bb7ffe9ac81a6f5f800.tar.gz",
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
