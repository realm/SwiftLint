import PackageDescription4

let package = Package(
  name: "SwiftLint",
  targets: [
    Target(name: "SwiftLintFramework"),
    Target(name: "swiftlint",
      dependencies: [
        .Target(name: "SwiftLintFramework")
      ]),
  ],
  dependencies: [
    .Package(url: "https://github.com/jpsim/SourceKitten.git", branch: "jp-swift-4"),
    .Package(url: "https://github.com/jpsim/Yams.git", branch: "jp-swift-4"),
    .Package(url: "https://github.com/jpsim/SwiftyTextTable.git", branch: "jp-swift-4"),
  ],
  swiftLanguageVersions: [3, 4]
)
