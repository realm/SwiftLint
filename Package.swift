import PackageDescription

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
    .Package(url: "/Users/jp/Projects/SourceKitten", majorVersion: 1),
    .Package(url: "/Users/jp/Projects/SwiftyTextTable", majorVersion: 1),
  ],
  swiftLanguageVersions: [3, 4]
)
