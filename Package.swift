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

let swiftLintPluginDependencies: [Target.Dependency]

#if os(macOS)
swiftLintPluginDependencies = [.target(name: "SwiftLintBinary")]
#else
swiftLintPluginDependencies = [.target(name: "swiftlint")]
#endif

let package = Package(
    name: "SwiftLint",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "swiftlint", targets: ["swiftlint"]),
        .library(name: "SwiftLintFramework", targets: ["SwiftLintFramework"]),
        .plugin(name: "SwiftLintBuildToolPlugin", targets: ["SwiftLintBuildToolPlugin"]),
        .plugin(name: "SwiftLintCommandPlugin", targets: ["SwiftLintCommandPlugin"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.1"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", exact: "601.0.0-prerelease-2025-02-12"),
        .package(url: "https://github.com/jpsim/SourceKitten.git", .upToNextMinor(from: "0.35.0")),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.6"),
        .package(url: "https://github.com/scottrhoyt/SwiftyTextTable.git", from: "0.9.0"),
        .package(url: "https://github.com/JohnSundell/CollectionConcurrencyKit.git", from: "0.2.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "1.8.4")),
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
            dependencies: swiftLintPluginDependencies,
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
            dependencies: swiftLintPluginDependencies,
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
            dependencies: ["SwiftLintCore"],
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
    ]
)

#if os(macOS)
package.targets.append(
    .binaryTarget(
        name: "SwiftLintBinary",
        url: "https://github.com/realm/SwiftLint/releases/download/0.58.2/SwiftLintBinary.artifactbundle.zip",
        checksum: "f2de7c148dba39bf0ad55ada8f60b15dde383c643c69f7eb2448bd2ed532f659"
    )
)
#endif
