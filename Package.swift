// swift-tools-version:5.9
import CompilerPluginSupport
import PackageDescription

let swiftFeatures: [SwiftSetting] = [
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("ImportObjcForwardDeclarations"),
    .enableUpcomingFeature("ForwardTrailingClosures"),
    .enableUpcomingFeature("ImplicitOpenExistentials"),
]
let strictConcurrency = [SwiftSetting.enableExperimentalFeature("StrictConcurrency")]

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
        .package(url: "https://github.com/swiftlang/swift-syntax.git", exact: "600.0.0"),
        .package(url: "https://github.com/jpsim/SourceKitten.git", .upToNextMinor(from: "0.35.0")),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.6"),
        .package(url: "https://github.com/scottrhoyt/SwiftyTextTable.git", from: "0.9.0"),
        .package(url: "https://github.com/JohnSundell/CollectionConcurrencyKit.git", from: "0.2.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", .upToNextMinor(from: "1.8.4")),
        .package(url: "https://github.com/ileitch/swift-filename-matcher", .upToNextMinor(from: "2.0.0")),
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
            swiftSettings: swiftFeatures
        ),
        .plugin(
            name: "SwiftLintBuildToolPlugin",
            capability: .buildTool(),
            dependencies: swiftLintPluginDependencies
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
            dependencies: swiftLintPluginDependencies
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
                .product(name: "FilenameMatcher", package: "swift-filename-matcher"),
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
            swiftSettings: swiftFeatures
        ),
        .testTarget(
            name: "CLITests",
            dependencies: [
                "SwiftLintFramework",
            ],
            swiftSettings: swiftFeatures
        ),
        .testTarget(
            name: "ExtraRulesTests",
            dependencies: [
                "SwiftLintFramework",
                "TestHelpers",
            ],
            swiftSettings: swiftFeatures
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
            swiftSettings: swiftFeatures
        ),
        .testTarget(
            name: "GeneratedTests",
            dependencies: [
                "SwiftLintFramework",
                "TestHelpers",
            ],
            swiftSettings: swiftFeatures
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
            swiftSettings: swiftFeatures
        ),
        .testTarget(
            name: "MacroTests",
            dependencies: [
                "SwiftLintCoreMacros",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
            ],
            swiftSettings: swiftFeatures
        ),
        .target(
            name: "TestHelpers",
            dependencies: [
                "SwiftLintFramework"
            ],
            path: "Tests/TestHelpers",
            swiftSettings: swiftFeatures
        ),
    ]
)

#if os(macOS)
// TODO: in the next release the artifactbundle is not suffixed with "-macos"
package.targets.append(
    .binaryTarget(
        name: "SwiftLintBinary",
        url: "https://github.com/realm/SwiftLint/releases/download/0.57.1/SwiftLintBinary-macos.artifactbundle.zip",
        checksum: "c88bf3e5bc1326d8ca66bc3f9eae786f2094c5172cd70b26b5f07686bb883899"
    )
)
#endif
