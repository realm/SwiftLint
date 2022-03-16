// swift-tools-version:5.5
import PackageDescription

#if canImport(CommonCrypto)
private let addCryptoSwift = false
#else
private let addCryptoSwift = true
#endif

#if os(macOS)
// TODO: Set back to true when a Swift 5.6 release of
// StaticInternalSwiftSyntaxParser is available
private let staticSwiftSyntax = false
#else
private let staticSwiftSyntax = false
#endif

let package = Package(
    name: "SwiftLint",
    platforms: [.macOS(.v10_12)],
    products: [
        .executable(name: "swiftlint", targets: ["swiftlint"]),
        .library(name: "SwiftLintFramework", targets: ["SwiftLintFramework"])
    ],
    dependencies: [
        .package(name: "swift-argument-parser", url: "https://github.com/apple/swift-argument-parser.git", .upToNextMinor(from: "1.0.3")),
        .package(url: "https://github.com/apple/swift-syntax.git", branch: "0.50600.0"),
        .package(url: "https://github.com/jpsim/SourceKitten.git", from: "0.32.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "4.0.2"),
        .package(url: "https://github.com/scottrhoyt/SwiftyTextTable.git", from: "0.9.0"),
    ] + (addCryptoSwift ? [.package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "1.4.3"))] : []),
    targets: [
        .executableTarget(
            name: "swiftlint",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "SwiftLintFramework",
                "SwiftyTextTable",
            ]
        ),
        .target(
            name: "SwiftLintFramework",
            dependencies: [
                .product(name: "SourceKittenFramework", package: "SourceKitten"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxParser", package: "swift-syntax"),
                "Yams",
            ]
            + (addCryptoSwift ? ["CryptoSwift"] : [])
            + (staticSwiftSyntax ? ["lib_InternalSwiftSyntaxParser"] : [])
        ),
        .testTarget(
            name: "SwiftLintFrameworkTests",
            dependencies: [
                "SwiftLintFramework"
            ],
            exclude: [
                "Resources",
            ]
        ),
    ] + (staticSwiftSyntax ? [.binaryTarget(
            name: "lib_InternalSwiftSyntaxParser",
            url: "https://github.com/keith/StaticInternalSwiftSyntaxParser/releases/download/5.5.2/lib_InternalSwiftSyntaxParser.xcframework.zip",
            checksum: "96bbc9ab4679953eac9ee46778b498cb559b8a7d9ecc658e54d6679acfbb34b8"
        )] : [])
)
