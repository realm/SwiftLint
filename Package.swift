// swift-tools-version:5.5
import PackageDescription

#if os(macOS)
private let addCryptoSwift = false
#else
private let addCryptoSwift = true
#endif

let frameworkDependencies: [Target.Dependency] = [
    .product(name: "SourceKittenFramework", package: "SourceKitten"),
    .product(name: "SwiftSyntax", package: "SwiftSyntax"),
    .product(name: "SwiftSyntaxBuilder", package: "SwiftSyntax"),
    .product(name: "SwiftParser", package: "SwiftSyntax"),
    "Yams",
]
+ (addCryptoSwift ? ["CryptoSwift"] : [])

let package = Package(
    name: "SwiftLint",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "swiftlint", targets: ["swiftlint"]),
        .library(name: "SwiftLintFramework", targets: ["SwiftLintFramework"])
    ],
    dependencies: [
        .package(name: "swift-argument-parser", url: "https://github.com/apple/swift-argument-parser.git", .upToNextMinor(from: "1.1.3")),
        .package(name: "SwiftSyntax", url: "https://github.com/CodaFi/swift-syntax.git", .revision("12174972766b29f57a45cec44bf7a2c4a887ff76")),
        .package(url: "https://github.com/jpsim/SourceKitten.git", from: "0.33.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.1"),
        .package(url: "https://github.com/scottrhoyt/SwiftyTextTable.git", from: "0.9.0"),
        .package(url: "https://github.com/JohnSundell/CollectionConcurrencyKit.git", from: "0.2.0")
    ] + (addCryptoSwift ? [.package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "1.5.1"))] : []),
    targets: [
        .executableTarget(
            name: "swiftlint",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "CollectionConcurrencyKit",
                "SwiftLintFramework",
                "SwiftyTextTable",
            ]
        ),
        .target(
            name: "SwiftLintFramework",
            dependencies: frameworkDependencies
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
    ]
)
