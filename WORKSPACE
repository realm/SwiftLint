workspace(name = "SwiftLint")

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
