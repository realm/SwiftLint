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
    .Package(url: "/root/SourceKitten", majorVersion: 1),
    .Package(url: "/root/SwiftyTextTable", majorVersion: 1),
  ],
  swiftLanguageVersions: [3, 4]
)
