// swift-tools-version:4.0
import PackageDescription

#if canImport(CommonCrypto)
private let addCryptoSwift = false
#else
private let addCryptoSwift = true
#endif

let package = Package(
    name: "SwiftLint",
    products: [
        .executable(name: "swiftlint", targets: ["swiftlint"]),
        .library(name: "SwiftLintFramework", targets: ["SwiftLintFramework"])
    ],
    dependencies: [
        .package(url: "https://github.com/Carthage/Commandant.git", from: "0.15.0"),
        .package(url: "https://github.com/jpsim/SourceKitten.git", from: "0.22.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "1.0.1"),
        .package(url: "https://github.com/scottrhoyt/SwiftyTextTable.git", from: "0.8.2"),
    ] + (addCryptoSwift ? [.package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "0.13.0")] : []),
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
            ] + (addCryptoSwift ? ["CryptoSwift"] : [])
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
    ]
)
