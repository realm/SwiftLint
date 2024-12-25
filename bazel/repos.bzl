load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def swiftlint_repos(bzlmod = False):
    """Fetches SwiftLint repositories"""
    if not bzlmod:
        http_archive(
            name = "SourceKittenFramework",
            sha256 = "604d2e5e547ef4280c959760cba0c9bd9be759c9555796cf7a73d9e1c9bcfc90",
            strip_prefix = "SourceKitten-0.37.2",
            url = "https://github.com/jpsim/SourceKitten/releases/download/0.37.2/SourceKitten-0.37.2.tar.gz",
        )

        http_archive(
            name = "SwiftArgumentParser",
            url = "https://github.com/apple/swift-argument-parser/archive/refs/tags/1.6.1.tar.gz",
            build_file = "@SwiftLint//bazel:SwiftArgumentParser.BUILD",
            sha256 = "d2fbb15886115bb2d9bfb63d4c1ddd4080cbb4bfef2651335c5d3b9dd5f3c8ba",
            strip_prefix = "swift-argument-parser-1.6.1",
        )

        http_archive(
            name = "Yams",
            url = "https://github.com/jpsim/Yams/archive/refs/tags/6.0.2.tar.gz",
            sha256 = "a1ae9733755f77fd56e4b01081baea2a756d8cd4b6b7ec58dd971b249318df48",
            strip_prefix = "Yams-6.0.2",
        )

        http_archive(
            name = "SWXMLHash",
            url = "https://github.com/drmohundro/SWXMLHash/archive/refs/tags/7.0.2.tar.gz",
            build_file = "@SwiftLint//bazel:SWXMLHash.BUILD",
            sha256 = "d7d600f062d6840b037fc1fb2ac3afce7a1c43ae430d78e22d7bd6f8e02cfc9d",
            strip_prefix = "SWXMLHash-7.0.2",
        )

    http_archive(
        name = "SwiftSyntax",
        sha256 = "15a66c06ea36fbbdaddcd708da0a51994fbc5a1e80932af02259b976f9a17a42",
        strip_prefix = "swift-syntax-603.0.0-prerelease-2025-10-30",
        url = "https://github.com/swiftlang/swift-syntax/archive/refs/tags/603.0.0-prerelease-2025-10-30.tar.gz",
        patches = ["@SwiftLint//bazel:SwiftSyntax.BUILD.bazel.patch"],
        patch_args = ["-p1"],
    )

    http_archive(
        name = "SwiftyTextTable",
        sha256 = "b77d403db9f33686caeb2a12986997fb02a0819e029e669c6b9554617c4fd6ae",
        build_file = "@SwiftLint//bazel:SwiftyTextTable.BUILD",
        strip_prefix = "SwiftyTextTable-0.9.0",
        url = "https://github.com/scottrhoyt/SwiftyTextTable/archive/refs/tags/0.9.0.tar.gz",
    )

    http_archive(
        name = "CollectionConcurrencyKit",
        sha256 = "9083fe6f8b4f820bfb5ef5c555b31953116f158ec113e94c6406686e78da34aa",
        build_file = "@SwiftLint//bazel:CollectionConcurrencyKit.BUILD",
        strip_prefix = "CollectionConcurrencyKit-0.2.0",
        url = "https://github.com/JohnSundell/CollectionConcurrencyKit/archive/refs/tags/0.2.0.tar.gz",
    )

    http_archive(
        name = "CryptoSwift",
        sha256 = "81b1ba186e2edcff47bcc2a3b6a242df083ba2f64bfb42209f79090cb8d7f889",
        build_file = "@SwiftLint//bazel:CryptoSwift.BUILD",
        strip_prefix = "CryptoSwift-1.9.0",
        url = "https://github.com/krzyzanowskim/CryptoSwift/archive/refs/tags/1.9.0.tar.gz",
    )

    http_archive(
        name = "FilenameMatcher",
        sha256 = "c0a6041be02ddd12f1cdde089f84dfa70e33e384cc476a786542a536d8401c6e",
        strip_prefix = "swift-filename-matcher-2.0.1",
        url = "https://github.com/ileitch/swift-filename-matcher/archive/refs/tags/2.0.1.tar.gz",
    )

def _swiftlint_repos_bzlmod(_):
    swiftlint_repos(bzlmod = True)

swiftlint_repos_bzlmod = module_extension(implementation = _swiftlint_repos_bzlmod)
