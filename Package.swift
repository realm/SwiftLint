// swift-tools-version:5.9
import CompilerPluginSupport
import PackageDescription

let swiftFeatures: [SwiftSetting] = [
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("ForwardTrailingClosures"),
    .enableUpcomingFeature("GlobalActorIsolatedTypesUsability"),
    .enableUpcomingFeature("ImplicitOpenExistentials"),
    .enableUpcomingFeature("ImportObjcForwardDeclarations"),
    .enableUpcomingFeature("InferSendableFromCaptures"),
]
let strictConcurrency = [SwiftSetting.enableExperimentalFeature("StrictConcurrency=complete")]
let targetedConcurrency = [SwiftSetting.enableExperimentalFeature("StrictConcurrency=targeted")]

let package = Package(
    name: "SwiftLint",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "swiftlint", targets: ["swiftlint"]),
        .library(name: "SwiftLintFramework", targets: ["SwiftLintFramework"]),
        .plugin(name: "SwiftLintBuildToolPlugin", targets: ["SwiftLintBuildToolPlugin"]),
        .plugin(name: "SwiftLintCommandPlugin", targets: ["SwiftLintCommandPlugin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", .upToNextMajor(from: "1.6.1")),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", exact: "602.0.0-prerelease-2025-08-11"),
        .package(url: "https://github.com/jpsim/SourceKitten.git", .upToNextMajor(from: "0.37.2")),
        .package(url: "https://github.com/jpsim/Yams.git", .upToNextMajor(from: "6.0.2")),
        .package(url: "https://github.com/scottrhoyt/SwiftyTextTable.git", .upToNextMajor(from: "0.9.0")),
        .package(url: "https://github.com/JohnSundell/CollectionConcurrencyKit.git", .upToNextMajor(from: "0.2.0")),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMajor(from: "1.9.0")),
    ],
    targets: [
        .executableTarget(
            name: "swiftlint",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "CollectionConcurrencyKit",
                "SwiftLintFramework",
                "SwiftyTextTable",
            ],
            swiftSettings: swiftFeatures + strictConcurrency
        ),
        .executableTarget(
            name: "swiftlint-dev",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                "SwiftLintFramework",
            ],
            swiftSettings: swiftFeatures + strictConcurrency
        ),
        .target(
            name: "SwiftLintFramework",
            dependencies: [
                "SwiftLintBuiltInRules",
                "SwiftLintCore",
                "SwiftLintExtraRules",
                "CollectionConcurrencyKit",
            ],
            swiftSettings: swiftFeatures + targetedConcurrency
        ),
        .plugin(
            name: "SwiftLintBuildToolPlugin",
            capability: .buildTool(),
            dependencies: [.target(name: "SwiftLintBinary")],
            packageAccess: false
        ),
        .plugin(
            name: "SwiftLintCommandPlugin",
            capability: .command(
                intent: .custom(verb: "swiftlint", description: "SwiftLint Command Plugin"),
                permissions: [
                    .writeToPackageDirectory(
                        reason: "When this command is run with the `--fix` option it may modify source files."
                    ),
                ]
            ),
            dependencies: [.target(name: "SwiftLintBinary")],
            packageAccess: false
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
                "SwiftLintCoreMacros",
            ],
            swiftSettings: swiftFeatures + strictConcurrency
        ),
        .target(
            name: "SwiftLintBuiltInRules",
            dependencies: [
                .product(name: "SwiftLexicalLookup", package: "swift-syntax"),
                "SwiftLintCore",
            ],
            swiftSettings: swiftFeatures + strictConcurrency
        ),
        .target(
            name: "SwiftLintExtraRules",
            dependencies: ["SwiftLintCore"],
            swiftSettings: swiftFeatures + strictConcurrency
        ),
        .target(name: "DyldWarningWorkaround"),
        .macro(
            name: "SwiftLintCoreMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
            ],
            path: "Source/SwiftLintCoreMacros",
            swiftSettings: swiftFeatures + strictConcurrency
        ),
        .testTarget(
            name: "BuiltInRulesTests",
            dependencies: [
                "SwiftLintBuiltInRules",
                "TestHelpers",
            ],
            exclude: [
                "Resources",
            ],
            swiftSettings: swiftFeatures + strictConcurrency
        ),
        .testTarget(
            name: "CLITests",
            dependencies: [
                "SwiftLintFramework",
            ],
            swiftSettings: swiftFeatures + strictConcurrency
        ),
        .testTarget(
            name: "CoreTests",
            dependencies: [
                "SwiftLintCore",
                "TestHelpers",
            ],
            exclude: [
                "Resources",
            ],
            swiftSettings: swiftFeatures + strictConcurrency
        ),
        .testTarget(
            name: "ExtraRulesTests",
            dependencies: [
                "SwiftLintFramework",
                "TestHelpers",
            ],
            swiftSettings: swiftFeatures + strictConcurrency
        ),
        .testTarget(
            name: "FrameworkTests",
            dependencies: [
                "SwiftLintFramework",
                "TestHelpers",
                "SwiftLintCoreMacros",
            ],
            exclude: [
                "Resources",
            ],
            swiftSettings: swiftFeatures + strictConcurrency
        ),
        .testTarget(
            name: "GeneratedTests",
            dependencies: [
                "SwiftLintFramework",
                "TestHelpers",
            ],
            swiftSettings: swiftFeatures + strictConcurrency
        ),
        .testTarget(
            name: "IntegrationTests",
            dependencies: [
                "SwiftLintFramework",
                "TestHelpers",
            ],
            exclude: [
                "default_rule_configurations.yml"
            ],
            swiftSettings: swiftFeatures + targetedConcurrency // Set to strict once SwiftLintFramework is updated
        ),
        .testTarget(
            name: "MacroTests",
            dependencies: [
                "SwiftLintCoreMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ],
            swiftSettings: swiftFeatures + strictConcurrency
        ),
        .target(
            name: "TestHelpers",
            dependencies: [
                "SwiftLintFramework"
            ],
            path: "Tests/TestHelpers",
            swiftSettings: swiftFeatures + strictConcurrency
        ),
        .binaryTarget(
            name: "SwiftLintBinary",
            url: "https://github.com/realm/SwiftLint/releases/download/0.61.0/SwiftLintBinary.artifactbundle.zip",
            checksum: "b765105fa5c5083fbcd35260f037b9f0d70e33992d0a41ba26f5f78a17dc65e7"
        ),
    ]
)
