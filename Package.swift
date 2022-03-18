// swift-tools-version:5.5
import PackageDescription

#if os(macOS)
private let addCryptoSwift = false
private let staticSwiftSyntax = true
#else
private let addCryptoSwift = true
private let staticSwiftSyntax = false
#endif

#if os(Linux) && compiler(<5.6)
private let swiftSyntaxFiveDotSix = false
#else
private let swiftSyntaxFiveDotSix = true
#endif

let frameworkDependencies: [Target.Dependency] = [
    .product(name: "SourceKittenFramework", package: "SourceKitten"),
    .product(name: "SwiftSyntax", package: "SwiftSyntax"),
    "Yams",
]
+ (addCryptoSwift ? ["CryptoSwift"] : [])
+ (staticSwiftSyntax ? ["lib_InternalSwiftSyntaxParser"] : [])
+ (swiftSyntaxFiveDotSix ? [.product(name: "SwiftSyntaxParser", package: "SwiftSyntax")] : [])

let package = Package(
    name: "SwiftLint",
    platforms: [.macOS(.v10_12)],
    products: [
        .executable(name: "swiftlint", targets: ["swiftlint"]),
        .library(name: "SwiftLintFramework", targets: ["SwiftLintFramework"])
    ],
    dependencies: [
        .package(name: "swift-argument-parser", url: "https://github.com/apple/swift-argument-parser.git", .upToNextMinor(from: "1.0.3")),
        .package(name: "SwiftSyntax", url: "https://github.com/apple/swift-syntax.git",
                 .exact(swiftSyntaxFiveDotSix ? "0.50600.1" : "0.50500.0")),
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
            dependencies: frameworkDependencies,
            // Pass `-dead_strip_dylibs` to ignore the dynamic version of `lib_InternalSwiftSyntaxParser`
            // that ships with SwiftSyntax because we want the static version from
            // `StaticInternalSwiftSyntaxParser`.
            linkerSettings: staticSwiftSyntax ? [.unsafeFlags(["-Xlinker", "-dead_strip_dylibs"])] : []
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
            url: "https://github.com/keith/StaticInternalSwiftSyntaxParser/releases/download/5.6/lib_InternalSwiftSyntaxParser.xcframework.zip",
            checksum: "88d748f76ec45880a8250438bd68e5d6ba716c8042f520998a438db87083ae9d"
        )] : [])
)
