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
    sha256 = "abd72022d996b09196f27c8ca67310ebded3ef2fd93d823db48dfcac923699e5",
    url = "https://github.com/krzysztofzablocki/Sourcery/releases/download/2.1.2/Sourcery-2.1.2.zip",
)
