workspace(name = "SwiftLint")

load("@bazel_tools//tools/build_defs/repo:git.bzl", "git_repository")

git_repository(
    name = "bazelruby_rules_ruby",
    commit = "cc2f5ce961f7fa34557264dd05c7597e634f31e1",
    remote = "https://github.com/bazelruby/rules_ruby.git",
    shallow_since = "1679251731 -0700",
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

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "Sourcery",
    build_file_content = """
load("@bazel_skylib//rules:native_binary.bzl", "native_binary")

native_binary(
name = "Sourcery",
src = "sourcery",
out = "sourcery",
visibility = ["//visibility:public"],
)
    """,
    strip_prefix = "bin",
    sha256 = "7489afb5c867efa06333a779a2430ccb52647a50f0e2280066cc78aea4532d8d",
    url = "https://github.com/krzysztofzablocki/Sourcery/releases/download/2.0.2/Sourcery-2.0.2.zip",
)
