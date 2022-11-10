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

http_archive(
    name = "IndexStore",
    sha256 = "5504aa5fd4f57ccea38c9f2537735eabdda8fdf1027f629f6d9443f6b64f7ef3",
    strip_prefix = "swift-index-store-1.2.0",
    url = "https://github.com/lyft/swift-index-store/archive/refs/tags/1.2.0.tar.gz",
)

load(
    "@IndexStore//:repositories.bzl",
    "swift_index_store_dependencies",
)

swift_index_store_dependencies()
