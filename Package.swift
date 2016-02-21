import PackageDescription

let package = Package(
  name: "SwiftLint",
  targets: [
    Target(name: "SwiftLintFramework"),
    Target(name: "swiftlint",
      dependencies: [
        .Target(name: "SwiftLintFramework")
      ]),
    Target(name: "SwiftLintFrameworkTests",
      dependencies: [
        .Target(name: "SwiftLintFramework")
      ]),
  ],
  dependencies: [
    .Package(url: "https://github.com/jpsim/SourceKitten.git", majorVersion: 0, minor: 11),
    .Package(url: "https://github.com/behrang/YamlSwift.git", majorVersion: 1),
    .Package(url: "https://github.com/norio-nomura/swift-corelibs-xctest.git", majorVersion: 0),
    .Package(url: "https://github.com/scottrhoyt/SwiftyTextTable.git", majorVersion: 0, minor: 2),
  ]
)
