// swift-tools-version:5.7
import PackageDescription

#if os(macOS)
private let addCryptoSwift = false
private let binaryPlugin = true
#else
private let addCryptoSwift = true
private let binaryPlugin = false
#endif

let frameworkDependencies: [Target.Dependency] = [
    .product(name: "IDEUtils", package: "swift-syntax"),
    .product(name: "SourceKittenFramework", package: "SourceKitten"),
    .product(name: "SwiftSyntax", package: "swift-syntax"),
    .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
    .product(name: "SwiftParser", package: "swift-syntax"),
    .product(name: "SwiftOperators", package: "swift-syntax"),
    "Yams",
]
+ (addCryptoSwift ? ["CryptoSwift"] : [])

let package = Package(
    name: "SwiftLint",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "swiftlint", targets: ["swiftlint"]),
        .library(name: "SwiftLintFramework", targets: ["SwiftLintFramework"]),
        .plugin(name: "SwiftLintPlugin", targets: ["SwiftLintPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMinor(from: "1.2.0")),
        .package(url: "https://github.com/apple/swift-syntax.git", revision: "a2d31e8880224f5a619f24bf58c122836faf99ff"),
        .package(url: "https://github.com/jpsim/SourceKitten.git", .upToNextMinor(from: "0.33.1")),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.1"),
        .package(url: "https://github.com/scottrhoyt/SwiftyTextTable.git", from: "0.9.0"),
        .package(url: "https://github.com/JohnSundell/CollectionConcurrencyKit.git", from: "0.2.0")
    ] + (addCryptoSwift ? [.package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "1.6.0"))] : []),
    targets: [
        .plugin(
            name: "SwiftLintPlugin",
            capability: .buildTool(),
            dependencies: [
                .target(name: binaryPlugin ? "SwiftLintBinary" : "swiftlint")
            ]
        ),
        .executableTarget(
            name: "swiftlint",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "CollectionConcurrencyKit",
                "SwiftLintFramework",
                "SwiftyTextTable",
            ]
        ),
        .testTarget(
            name: "CLITests",
            dependencies: [
                "swiftlint"
            ]
        ),
        .target(
            name: "SwiftLintFramework",
            dependencies: frameworkDependencies
        ),
        .target(
            name: "SwiftLintTestHelpers",
            dependencies: [
                "SwiftLintFramework"
            ],
            path: "Tests/SwiftLintTestHelpers"
        ),
        .testTarget(
            name: "SwiftLintFrameworkTests",
            dependencies: [
                "SwiftLintFramework",
                "SwiftLintTestHelpers"
            ],
            exclude: [
                "Resources",
            ]
        ),
        .testTarget(
            name: "GeneratedTests",
            dependencies: [
                "SwiftLintFramework",
                "SwiftLintTestHelpers"
            ]
        ),
        .testTarget(
            name: "IntegrationTests",
            dependencies: [
                "SwiftLintFramework",
                "SwiftLintTestHelpers"
            ]
        ),
        .testTarget(
            name: "ExtraRulesTests",
            dependencies: [
                "SwiftLintFramework",
                "SwiftLintTestHelpers"
            ]
        ),
        .binaryTarget(
            name: "SwiftLintBinary",
            url: "https://github.com/realm/SwiftLint/releases/download/0.50.3/SwiftLintBinary-macos.artifactbundle.zip",
            checksum: "abe7c0bb505d26c232b565c3b1b4a01a8d1a38d86846e788c4d02f0b1042a904"
        )
    ]
)
