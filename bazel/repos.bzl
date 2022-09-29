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

    # https://github.com/apple/swift-syntax/pull/807
    http_archive(
        name = "com_github_apple_swift_syntax",
        sha256 = "54e092e48d68c95b7431c6057d4d60d51ccdb8a488f21910a3963da843643af8",
        build_file = "@SwiftLint//bazel:SwiftSyntax.BUILD",
        strip_prefix = "swift-syntax-62c674973d2ad6ef2e3e30c6028374e130bac6a6",
        url = "https://github.com/jpsim/swift-syntax/archive/62c674973d2ad6ef2e3e30c6028374e130bac6a6.tar.gz",
    )

    http_archive(
        name = "com_github_johnsundell_collectionconcurrencykit",
        sha256 = "9083fe6f8b4f820bfb5ef5c555b31953116f158ec113e94c6406686e78da34aa",
        build_file = "@SwiftLint//bazel:CollectionConcurrencyKit.BUILD",
        strip_prefix = "CollectionConcurrencyKit-0.2.0",
        url = "https://github.com/JohnSundell/CollectionConcurrencyKit/archive/refs/tags/0.2.0.tar.gz",
    )

    http_archive(
        name = "com_github_krzyzanowskim_cryptoswift",
        sha256 = "8460b44f8378c4201d15bd2617b2d8d1dbf5fef28cb8886ced4b72ad201e2361",
        build_file = "@SwiftLint//bazel:CryptoSwift.BUILD",
        strip_prefix = "CryptoSwift-1.5.1",
        url = "https://github.com/krzyzanowskim/CryptoSwift/archive/refs/tags/1.5.1.tar.gz",
    )
