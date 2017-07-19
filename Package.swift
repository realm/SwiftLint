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
    .Package(url: "https://github.com/Carthage/Commandant.git", majorVersion: 0, minor: 12),
    .Package(url: "https://github.com/jpsim/SourceKitten.git", majorVersion: 0, minor: 18),
    .Package(url: "https://github.com/jpsim/Yams.git", majorVersion: 0, minor: 3),
    .Package(url: "https://github.com/scottrhoyt/SwiftyTextTable.git", majorVersion: 0, minor: 5),
  ]
)
