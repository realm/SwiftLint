// swift-tools-version:4.0
import PackageDescription

let package = Package(
  name: "SwiftLint",
  products: [
    .executable(name: "swiftlint", targets: ["swiftlint"]),
    .library(name: "SwiftLintFramework", targets: ["SwiftLintFramework"])
  ],
  dependencies: [
    .package(url: "https://github.com/Carthage/Commandant.git", from: "0.12.0"),
    .package(url: "https://github.com/jpsim/Yams.git", .branch("master")),
    .package(url: "https://github.com/jpsim/SourceKitten.git", .branch("jp-swift-4")),
    .package(url: "https://github.com/jpsim/SwiftyTextTable.git", .branch("jp-swift-4")),
  ],
  targets: [
    .target(
      name: "swiftlint",
      dependencies: [
        "Commandant",
        "SwiftLintFramework",
        "SwiftyTextTable"
      ]
    ),
    .target(
      name: "SwiftLintFramework",
      dependencies: [
        "SourceKittenFramework"
      ]
    ),
    .testTarget(
      name: "SwiftLintFrameworkTests",
      dependencies: [
        "SwiftLintFramework"
      ]
    )
  ],
  swiftLanguageVersions: [3, 4]
)
