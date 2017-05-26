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
    .Package(url: "https://github.com/jpsim/SourceKitten.git", majorVersion: 0, minor: 17),
    .Package(url: "https://github.com/jpsim/Yams.git", majorVersion: 0, minor: 3),
    .Package(url: "https://github.com/jpsim/SwiftyTextTable.git", majorVersion: 0, minor: 5),
  ],
  swiftLanguageVersions: [3, 4]
)
