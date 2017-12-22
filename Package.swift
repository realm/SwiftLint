// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "SwiftLint",
    products: [
        .executable(name: "swiftlint", targets: ["swiftlint"]),
        .library(name: "SwiftLintFramework", targets: ["SwiftLintFramework"])
    ],
    dependencies: [
        .package(url: "https://github.com/Carthage/Commandant.git", .branch("master")),
        .package(url: "https://github.com/jpsim/SourceKitten.git", from: "0.18.4"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "0.4.1"),
        .package(url: "https://github.com/scottrhoyt/SwiftyTextTable.git", from: "0.8.0"),
    ],
    targets: [
        .target(
            name: "swiftlint",
            dependencies: [
                "Commandant",
                "SwiftLintFramework",
                "SwiftyTextTable",
            ]
        ),
        .target(
            name: "SwiftLintFramework",
            dependencies: [
                "SourceKittenFramework",
                "Yams",
            ]
        ),
        .testTarget(
            name: "SwiftLintFrameworkTests",
            dependencies: [
                "SwiftLintFramework"
            ],
            exclude: [
                "Resources",
            ]
        )
    ],
    swiftLanguageVersions: [3, 4]
)
