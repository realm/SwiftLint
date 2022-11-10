load("@build_bazel_rules_apple//apple:apple.bzl", "apple_static_framework_import")

apple_static_framework_import(
    name = "libIndexStore",
    framework_imports = ["libIndexStore.xcframework/macos-arm64_x86_64/libIndexStore.framework/libIndexStore"],
    visibility = ["@com_github_lyft_index_store//:__pkg__"],
)
