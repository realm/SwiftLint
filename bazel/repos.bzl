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
        sha256 = "032a14f76285b2edc66f48ff968c3bf0bd1775e2afb8ad3eebb837e6e2519d6c",
        build_file = "@SwiftLint//bazel:SwiftSyntax.BUILD",
        strip_prefix = "swift-syntax-093e5ee151d206454e2c1950d81333c4d4a4472e",
        url = "https://github.com/apple/swift-syntax/archive/093e5ee151d206454e2c1950d81333c4d4a4472e.tar.gz",
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
        sha256 = "5d500caf1817beb0a63467ef14d3274ae19449bcf05853a257673d0c27f4b761",
        build_file = "@SwiftLint//bazel:CryptoSwift.BUILD",
        strip_prefix = "CryptoSwift-1.6.0",
        url = "https://github.com/krzyzanowskim/CryptoSwift/archive/refs/tags/1.6.0.tar.gz",
    )
