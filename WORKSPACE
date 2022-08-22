workspace(name = "SwiftLint")

load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")

http_archive(
    name = "build_bazel_rules_apple",
    sha256 = "36072d4f3614d309d6a703da0dfe48684ec4c65a89611aeb9590b45af7a3e592",
    url = "https://github.com/bazelbuild/rules_apple/releases/download/1.0.1/rules_apple.1.0.1.tar.gz",
)

http_archive(
    name = "build_bazel_rules_swift",
    sha256 = "7a25fa865205f96fe4924ed137fed02a1b9529afd82ffd14e52186a0aa222cad",
    strip_prefix = "rules_swift-469db13330e94af864540d50acdfc742998ef292",
    url = "https://github.com/bazelbuild/rules_swift/archive/469db13330e94af864540d50acdfc742998ef292.tar.gz",
)

load(
    "@build_bazel_rules_apple//apple:repositories.bzl",
    "apple_rules_dependencies",
)

apple_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:repositories.bzl",
    "swift_rules_dependencies",
)

swift_rules_dependencies()

load(
    "@build_bazel_rules_swift//swift:extras.bzl",
    "swift_rules_extra_dependencies",
)

swift_rules_extra_dependencies()

load("//bazel:repos.bzl", "swiftlint_repos")

swiftlint_repos()

load("//bazel:deps.bzl", "swiftlint_deps")

swiftlint_deps()

http_archive(
    name = "com_github_buildbuddy_io_rules_xcodeproj",
    sha256 = "1bfc8589398afc31c47c3cb402f848c89ea11f8992c3f1c8e93efafa23619a7f",
    # https://github.com/buildbuddy-io/rules_xcodeproj/pull/900
    strip_prefix = "rules_xcodeproj-da3c32c91653cd98d4cb0bb7ffe9ac81a6f5f800",
    url = "https://github.com/buildbuddy-io/rules_xcodeproj/archive/da3c32c91653cd98d4cb0bb7ffe9ac81a6f5f800.tar.gz",
)

load("@com_github_buildbuddy_io_rules_xcodeproj//xcodeproj:repositories.bzl", "xcodeproj_rules_dependencies")

xcodeproj_rules_dependencies()
