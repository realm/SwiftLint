load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

def swiftlint_repos():
    """Fetches SwiftLint repositories"""
    http_archive(
        name = "com_github_jpsim_sourcekitten",
        sha256 = "f3e17da70aa039a54df45d648c20c84fb13f4f70df33df88bcf69b06f8714304",
        strip_prefix = "SourceKitten-24fc942861f1446c2aefb19ebc94a471b2abea0f",
        url = "https://github.com/jpsim/SourceKitten/archive/24fc942861f1446c2aefb19ebc94a471b2abea0f.tar.gz",
    )

    http_archive(
        name = "swiftlint_com_github_scottrhoyt_swifty_text_table",
        sha256 = "b77d403db9f33686caeb2a12986997fb02a0819e029e669c6b9554617c4fd6ae",
        build_file = "@com_github_realm_swiftlint//bazel:SwiftyTextTable.BUILD",
        strip_prefix = "SwiftyTextTable-0.9.0",
        url = "https://github.com/scottrhoyt/SwiftyTextTable/archive/refs/tags/0.9.0.tar.gz",
    )

    http_archive(
        name = "com_github_keith_swift_syntax_bazel",
        sha256 = "f83b8449f84e29d263d2b0ceb9d2ae7f88c9f2a81f4b10035e94073664507507",
        strip_prefix = "swift-syntax-bazel-13.3.13E113",
        url = "https://github.com/keith/swift-syntax-bazel/archive/refs/tags/13.3.13E113.tar.gz",
    )

    http_archive(
        name = "com_github_krzyzanowskim_cryptoswift",
        sha256 = "8460b44f8378c4201d15bd2617b2d8d1dbf5fef28cb8886ced4b72ad201e2361",
        build_file = "@com_github_realm_swiftlint//bazel:CryptoSwift.BUILD",
        strip_prefix = "CryptoSwift-1.5.1",
        url = "https://github.com/krzyzanowskim/CryptoSwift/archive/refs/tags/1.5.1.tar.gz",
    )
