load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def swiftlint_repos():
    """Fetches SwiftLint repositories"""
    http_archive(
        name = "com_github_jpsim_sourcekitten",
        sha256 = "beeddf444ff079dc2248c5b9b0df3e6ee9d886b03a68c4e372e955e5e76c16b9",
        strip_prefix = "SourceKitten-0.33.0",
        url = "https://github.com/jpsim/SourceKitten/archive/refs/tags/0.33.0.tar.gz",
    )

    http_archive(
        name = "swiftlint_com_github_scottrhoyt_swifty_text_table",
        sha256 = "b77d403db9f33686caeb2a12986997fb02a0819e029e669c6b9554617c4fd6ae",
        build_file = "@SwiftLint//bazel:SwiftyTextTable.BUILD",
        strip_prefix = "SwiftyTextTable-0.9.0",
        url = "https://github.com/scottrhoyt/SwiftyTextTable/archive/refs/tags/0.9.0.tar.gz",
    )

    http_archive(
        name = "com_github_apple_swift_syntax",
        sha256 = "2fca7c4c4d9fdc5872ed99f2ea8aa840a0063ba546adf2c6ee94c8fcf4de0e20",
        build_file = "@SwiftLint//bazel:SwiftSyntax.BUILD",
        strip_prefix = "swift-syntax-4f2e1537f39583f635d4a343128749d650157537",
        url = "https://github.com/apple/swift-syntax/archive/4f2e1537f39583f635d4a343128749d650157537.tar.gz",
    )

    http_archive(
        name = "com_github_johnsundell_collectionconcurrencykit",
        sha256 = "9083fe6f8b4f820bfb5ef5c555b31953116f158ec113e94c6406686e78da34aa",
        build_file = "@SwiftLint//bazel:CollectionConcurrencyKit.BUILD",
        strip_prefix = "CollectionConcurrencyKit-0.2.0",
        url = "https://github.com/JohnSundell/CollectionConcurrencyKit/archive/refs/tags/0.2.0.tar.gz",
    )

    # https://github.com/krzyzanowskim/CryptoSwift/pull/989
    http_archive(
        name = "com_github_jpsim_cryptoswift",
        sha256 = "9371d81d8c9a9673b0a22acbc3cc4b62862c58af60daf76928126c7f80cf7783",
        build_file = "@SwiftLint//bazel:CryptoSwift.BUILD",
        strip_prefix = "CryptoSwift-782caf96909e15d0cbba2db2c53923bd3a6a865d",
        url = "https://github.com/jpsim/CryptoSwift/archive/782caf96909e15d0cbba2db2c53923bd3a6a865d.tar.gz",
    )
