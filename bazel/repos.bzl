load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def swiftlint_repos(bzlmod = False):
    """Fetches SwiftLint repositories"""
    if not bzlmod:
        http_archive(
            name = "com_github_jpsim_sourcekitten",
            sha256 = "7a38debb93ef11504f6b6a776be598095591fae7e128263754d041c5ada8e856",
            strip_prefix = "SourceKitten-0.34.0",
            url = "https://github.com/jpsim/SourceKitten/archive/refs/tags/0.34.0.tar.gz",
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
        # sha256 = "12d1ee4ac0d1b220777709fe66790bfb263d9a104c58019db51c59dbd772cd77", # SwiftSyntax sha256
        build_file = "@SwiftLint//bazel:SwiftSyntax.BUILD",
        strip_prefix = "swift-syntax-80b28f4ea6dd706a2e2f199f11a6ea5622d0784a",
        url = "https://github.com/apple/swift-syntax/archive/80b28f4ea6dd706a2e2f199f11a6ea5622d0784a.tar.gz",
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
        name = "com_github_krzyzanowskim_cryptoswift",
        sha256 = "bbabd3a5c5f50683d6eeb90cf3f7f7184e18065beaec7cccd2059ed3c9bac2ed",
        build_file = "@SwiftLint//bazel:CryptoSwift.BUILD",
        strip_prefix = "CryptoSwift-ea07950124f7e44e88bd783bf29e6691a7866228",
        url = "https://github.com/krzyzanowskim/CryptoSwift/archive/ea07950124f7e44e88bd783bf29e6691a7866228.tar.gz",
    )

def _swiftlint_repos_bzlmod(_):
    swiftlint_repos(bzlmod = True)

swiftlint_repos_bzlmod = module_extension(implementation = _swiftlint_repos_bzlmod)
