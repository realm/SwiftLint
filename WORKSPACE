workspace(name = "SwiftLint")

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
