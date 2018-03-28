// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "SwiftLint",
    products: [
//        .executable(name: "swiftlint", targets: ["swiftlint"]),
        .library(name: "SwiftLintFramework", targets: ["SwiftLintFramework"]),
        .library(name: "SwiftLintKit", targets: ["SwiftLintKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/Carthage/Commandant.git", from: "0.13.0"),
        .package(url: "https://github.com/jpsim/SourceKitten.git", from: "0.19.1"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "0.5.0"),
        .package(url: "https://github.com/scottrhoyt/SwiftyTextTable.git", from: "0.8.0"),
    ],
    targets: [
//        .target(
//            name: "swiftlint",
//            dependencies: [
//                "Commandant",
//                "SwiftLintFramework",
//                "SwiftyTextTable",
//            ]
//        ),
        .target(
            name: "SwiftLintFramework",
            dependencies: [
                "SourceKittenFramework",
                "Yams",
            ]
        ),
        .target(
            name: "SwiftLintKit",
            dependencies: [
                "Commandant",
                "SwiftLintFramework",
                "SwiftyTextTable",
                ],
            path: "Source/swiftlint"
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
