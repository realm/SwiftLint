load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def swiftlint_repos(bzlmod = False):
    """Fetches SwiftLint repositories"""
    if not bzlmod:
        http_archive(
            name = "com_github_jpsim_sourcekitten",
            sha256 = "604d2e5e547ef4280c959760cba0c9bd9be759c9555796cf7a73d9e1c9bcfc90",
            strip_prefix = "SourceKitten-0.37.2",
            url = "https://github.com/jpsim/SourceKitten/releases/download/0.37.2/SourceKitten-0.37.2.tar.gz",
        )

        http_archive(
            name = "SwiftSyntax",
            sha256 = "02450ab3fd1d676fffd3719f3263293c51d567cae741fc340c68930388781286",
            strip_prefix = "swift-syntax-601.0.1",
            url = "https://github.com/swiftlang/swift-syntax/archive/refs/tags/601.0.1.tar.gz",
        )

        http_archive(
            name = "com_github_apple_swift_argument_parser",
            url = "https://github.com/apple/swift-argument-parser/archive/refs/tags/1.5.0.tar.gz",
            build_file = "@SwiftLint//bazel:SwiftArgumentParser.BUILD",
            sha256 = "946a4cf7bdd2e4f0f8b82864c56332238ba3f0a929c6d1a15f55affdb10634e6",
            strip_prefix = "swift-argument-parser-1.5.0",
        )

        http_archive(
            name = "com_github_jpsim_yams",
            url = "https://github.com/jpsim/Yams/releases/download/6.0.1/Yams-6.0.1.tar.gz",
            sha256 = "76afe79db05acb0eda4910e0b9da6a8562ad6139ac317daa747cd829beb93b9e",
            strip_prefix = "Yams-6.0.1",
        )

        http_archive(
            name = "com_github_drmohundro_SWXMLHash",
            url = "https://github.com/drmohundro/SWXMLHash/archive/refs/tags/7.0.2.tar.gz",
            build_file = "@SwiftLint//bazel:SWXMLHash.BUILD",
            sha256 = "d7d600f062d6840b037fc1fb2ac3afce7a1c43ae430d78e22d7bd6f8e02cfc9d",
            strip_prefix = "SWXMLHash-7.0.2",
        )

    http_archive(
        name = "swiftlint_com_github_scottrhoyt_swifty_text_table",
        sha256 = "b77d403db9f33686caeb2a12986997fb02a0819e029e669c6b9554617c4fd6ae",
        build_file = "@SwiftLint//bazel:SwiftyTextTable.BUILD",
        strip_prefix = "SwiftyTextTable-0.9.0",
        url = "https://github.com/scottrhoyt/SwiftyTextTable/archive/refs/tags/0.9.0.tar.gz",
    )

    http_archive(
        name = "swiftlint_com_github_johnsundell_collectionconcurrencykit",
        sha256 = "9083fe6f8b4f820bfb5ef5c555b31953116f158ec113e94c6406686e78da34aa",
        build_file = "@SwiftLint//bazel:CollectionConcurrencyKit.BUILD",
        strip_prefix = "CollectionConcurrencyKit-0.2.0",
        url = "https://github.com/JohnSundell/CollectionConcurrencyKit/archive/refs/tags/0.2.0.tar.gz",
    )

    http_archive(
        name = "swiftlint_com_github_krzyzanowskim_cryptoswift",
        sha256 = "69b23102ff453990d03aff4d3fabd172d0667b2b3ed95730021d60a0f8d50d14",
        build_file = "@SwiftLint//bazel:CryptoSwift.BUILD",
        strip_prefix = "CryptoSwift-1.8.4",
        url = "https://github.com/krzyzanowskim/CryptoSwift/archive/refs/tags/1.8.4.tar.gz",
    )

def _swiftlint_repos_bzlmod(_):
    swiftlint_repos(bzlmod = True)

swiftlint_repos_bzlmod = module_extension(implementation = _swiftlint_repos_bzlmod)
