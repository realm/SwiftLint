import PackageDescription

let package = Package(
  name: "SwiftLint",
  targets: [
    Target(name: "SwiftLintFramework"),
    Target(name: "swiftlint",
      dependencies: [
        .Target(name: "SwiftLintFramework")
      ])
  ],
  dependencies: [
    .Package(url: "https://github.com/norio-nomura/SourceKitten.git", majorVersion: 0, minor: 8),
    .Package(url: "https://github.com/norio-nomura/Commandant.git", majorVersion: 0, minor: 8),
    .Package(url: "https://github.com/norio-nomura/YamlSwift.git", majorVersion: 1),
  ],
  exclude: ["Source/SwiftLintFrameworkTests"]
)
