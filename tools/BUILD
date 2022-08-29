load("@bazelruby_rules_ruby//ruby:defs.bzl", "ruby_binary")

exports_files(["test-analyze.sh"])

ruby_binary(
    name = "danger",
    main = "@bundle//:bin/danger",
    deps = ["@bundle//:bin"],
)
