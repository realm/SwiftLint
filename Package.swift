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
        .package(name: "SwiftSyntax", url: "https://github.com/apple/swift-syntax.git", .revision("093e5ee151d206454e2c1950d81333c4d4a4472e")),
        .package(url: "https://github.com/jpsim/SourceKitten.git", from: "0.33.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.1"),
        .package(url: "https://github.com/scottrhoyt/SwiftyTextTable.git", from: "0.9.0"),
        .package(url: "https://github.com/JohnSundell/CollectionConcurrencyKit.git", from: "0.2.0")
    ] + (addCryptoSwift ? [.package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "1.6.0"))] : []),
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
        .testTarget(
          name: "swiftlintTests",
          dependencies: [
            "swiftlint"
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
