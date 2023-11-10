load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def swiftlint_repos(bzlmod = False):
    """Fetches SwiftLint repositories"""
    if not bzlmod:
        http_archive(
            name = "com_github_jpsim_sourcekitten",
            sha256 = "fcc5ea783e6a0b58b3873c3d551c0ff7a146fdd536e66e1d37af13b1f52df3d4",
            strip_prefix = "SourceKitten-0.34.1",
            url = "https://github.com/jpsim/SourceKitten/releases/download/0.34.1/SourceKitten-0.34.1.tar.gz",
        )

        http_archive(
            name = "SwiftSyntax",
            sha256 = "1cddda9f7d249612e3d75d4caa8fd9534c0621b8a890a7d7524a4689bce644f1",
            strip_prefix = "swift-syntax-509.0.0",
            url = "https://github.com/apple/swift-syntax/archive/refs/tags/509.0.0.tar.gz",
        )

    http_archive(
        name = "swiftlint_com_github_scottrhoyt_swifty_text_table",
        sha256 = "b77d403db9f33686caeb2a12986997fb02a0819e029e669c6b9554617c4fd6ae",
        build_file = "@SwiftLint//bazel:SwiftyTextTable.BUILD",
        strip_prefix = "SwiftyTextTable-0.9.0",
        url = "https://github.com/scottrhoyt/SwiftyTextTable/archive/refs/tags/0.9.0.tar.gz",
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
        sha256 = "3d649cccfe9ae0572163cde0201f013d10349a035c15225e7a4bd83c85fb0d1d",
        build_file = "@SwiftLint//bazel:CryptoSwift.BUILD",
        strip_prefix = "CryptoSwift-1.8.0",
        url = "https://github.com/krzyzanowskim/CryptoSwift/archive/refs/tags/1.8.0.tar.gz",
    )

def _swiftlint_repos_bzlmod(_):
    swiftlint_repos(bzlmod = True)

swiftlint_repos_bzlmod = module_extension(implementation = _swiftlint_repos_bzlmod)
