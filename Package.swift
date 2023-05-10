// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "SwiftLint",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "swiftlint", targets: ["swiftlint"]),
        .library(name: "SwiftLintFramework", targets: ["SwiftLintFramework"]),
        .plugin(name: "SwiftLintPlugin", targets: ["SwiftLintPlugin"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMinor(from: "1.2.1")),
        .package(url: "https://github.com/apple/swift-syntax.git", exact: "509.0.0-swift-DEVELOPMENT-SNAPSHOT-2023-05-02-a"),
        .package(url: "https://github.com/jpsim/SourceKitten.git", .upToNextMinor(from: "0.34.1")),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.5"),
        .package(url: "https://github.com/scottrhoyt/SwiftyTextTable.git", from: "0.9.0"),
        .package(url: "https://github.com/JohnSundell/CollectionConcurrencyKit.git", from: "0.2.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "1.7.1"))
    ],
    targets: [
        .plugin(
            name: "SwiftLintPlugin",
            capability: .buildTool(),
            dependencies: [
                .target(name: "SwiftLintBinary", condition: .when(platforms: [.macOS])),
                .target(name: "swiftlint", condition: .when(platforms: [.linux]))
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
            name: "SwiftLintCore",
            dependencies: [
                .product(name: "CryptoSwift", package: "CryptoSwift", condition: .when(platforms: [.linux])),
                .target(name: "DyldWarningWorkaround", condition: .when(platforms: [.macOS])),
                .product(name: "SourceKittenFramework", package: "SourceKitten"),
                .product(name: "SwiftIDEUtils", package: "swift-syntax"),
                .product(name: "SwiftOperators", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftyTextTable", package: "SwiftyTextTable"),
                .product(name: "Yams", package: "Yams"),
            ]
        ),
        .target(
            name: "SwiftLintBuiltInRules",
            dependencies: ["SwiftLintCore"]
        ),
        .target(
            name: "SwiftLintExtraRules",
            dependencies: ["SwiftLintCore"]
        ),
        .target(
            name: "SwiftLintFramework",
            dependencies: [
                "SwiftLintBuiltInRules",
                "SwiftLintCore",
                "SwiftLintExtraRules"
            ]
        ),
        .target(name: "DyldWarningWorkaround"),
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
            url: "https://github.com/realm/SwiftLint/releases/download/0.52.0/SwiftLintBinary-macos.artifactbundle.zip",
            checksum: "7b956238d2937084a66b89cb68cfcde673f85d1202b37edea9c3f193dec8a2d9"
        )
    ]
)
