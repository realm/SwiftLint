import Darwin
import Foundation
import SwiftLintFramework

#if canImport(CommonCrypto)
import CommonCrypto
import Foundation

private extension Data {
    func sha256() -> Data {
        withUnsafeBytes { bytes in
            let count = Int(CC_SHA256_DIGEST_LENGTH)
            return Data(Array(unsafeUninitializedCapacity: count) { hash, initializedCount in
                CC_SHA256(bytes.baseAddress, CC_LONG(count), hash.baseAddress)
                initializedCount = count
            })
        }
    }

    func toHexString() -> String {
        reduce(into: "") { $0.append(String(format: "%02x", $1)) }
    }
}

private extension String {
    func sha256() -> String {
        data(using: .utf8)!.sha256().toHexString()
    }
}
#endif

// TODO: Share models across main library and plugin
// TODO: Measure performance impact
// TODO: Find a way to send the serialized syntax tree over the wire

private struct SwiftLintPluginLintResult: Codable {
    let violations: [SwiftLintPluginStyleViolation]
}

private struct SwiftLintPluginStyleViolation: Codable {
    let ruleIdentifier: String
    let ruleDescription: String
    let ruleName: String
    let severity: SwiftLintPluginViolationSeverity
    let location: SwiftLintPluginLocation
    let reason: String
}

private enum SwiftLintPluginViolationSeverity: String, Codable {
    case warning
    case error
}

private struct SwiftLintPluginLocation: Codable {
    let file: String?
    let line: Int?
    let character: Int?
}

private func findExecutable(_ name: String) throws -> URL {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
    process.arguments = [name]

    let pipe = Pipe()
    process.standardOutput = pipe

    try process.run()
    process.waitUntilExit()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    guard let string = String(data: data, encoding: .utf8),
          let path = string.split(separator: "\n").first
    else {
        throw NSError(domain: "ExecutableNotFound", code: 1, userInfo: nil)
    }

    return URL(fileURLWithPath: String(path))
}

private let compilationMode = "release"

private let tempDir = FileManager.default.temporaryDirectory
    .appendingPathComponent("swiftlint_plugins_\(FileManager.default.currentDirectoryPath.sha256())")
private let libURL = tempDir.appending(path: ".build/\(compilationMode)/libSwiftCLIPlugin.dylib")

private let pluginManifest = """
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "swift-cli-plugin-lib",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "SwiftCLIPlugin", type: .dynamic, targets: ["swift-cli-plugin-lib"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.1"),
    ],
    targets: [
        .target(
            name: "swift-cli-plugin-lib",
            dependencies: [
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ]
        ),
    ]
)
"""

private let pluginCodegen = """
import Foundation
import SwiftParser
import SwiftSyntax

struct SwiftLintPluginLintResult: Codable {
    let violations: [SwiftLintPluginStyleViolation]
}

struct SwiftLintPluginStyleViolation: Codable {
    let ruleIdentifier: String
    let ruleDescription: String
    let ruleName: String
    let severity: SwiftLintPluginViolationSeverity
    let location: SwiftLintPluginLocation
    let reason: String
}

enum SwiftLintPluginViolationSeverity: String, Codable {
    case warning
    case error
}

struct SwiftLintPluginLocation: Codable {
    let file: String?
    let line: Int?
    let character: Int?

    init(file: String?, line: Int?, character: Int?) {
        self.file = file
        self.line = line
        self.character = character
    }

    init(_ sourceLocation: SourceLocation) {
        file = sourceLocation.file
        line = sourceLocation.line
        character = sourceLocation.column
    }
}


@_cdecl("swiftlintPluginLintFile")
public func swiftlintPluginLintFile(file: String) -> Data {
    let violations = runPlugin(file: file)
    if violations.isEmpty {
        return Data() // Fast path for no violations
    }
    let payload = SwiftLintPluginLintResult(violations: violations)
    return try! JSONEncoder().encode(payload)
}
"""

func pluginPackageManifestURL() -> URL {
    tempDir.appendingPathComponent("Package.swift")
}

func generatePluginPackage() throws {
    try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

    try pluginManifest.write(to: pluginPackageManifestURL(), atomically: true, encoding: .utf8)

    let sourcesDir = tempDir.appendingPathComponent("Sources")
    try FileManager.default.createDirectory(at: sourcesDir, withIntermediateDirectories: true)

    let pluginURL = sourcesDir.appendingPathComponent("plugin.swift")
    if !FileManager.default.fileExists(atPath: pluginURL.path(percentEncoded: false)) {
        try FileManager.default.createSymbolicLink(
            at: pluginURL,
            withDestinationURL: URL(fileURLWithPath: ".swiftlint/rules/plugin.swift")
        )
    }
    let codegenURL = sourcesDir.appendingPathComponent("plugin_codegen.swift")
    try pluginCodegen.write(to: codegenURL, atomically: true, encoding: .utf8)
}

func buildThePlugin() {
    do {
        try generatePluginPackage()
        let buildProcess = Process()
        let swiftURL = try findExecutable("swift")

        buildProcess.executableURL = swiftURL
        buildProcess.arguments = ["build", "-c", compilationMode]
        buildProcess.currentDirectoryURL = tempDir

        try buildProcess.run()
        buildProcess.waitUntilExit()

        if buildProcess.terminationStatus != 0 {
            print("Build failed with exit code \(buildProcess.terminationStatus)")
        } else {
            print("Build succeeded at path \(tempDir)")
        }
    } catch {
        print("Failed to run command: \(error)")
    }
}

func getPluginViolations(forFile file: String) throws -> [StyleViolation] {
    guard let handle = dlopen(libURL.path, RTLD_NOW) else {
        print("Unable to load library")
        return []
    }

    defer {
        dlclose(handle)
    }

    guard let symbol = dlsym(handle, "swiftlintPluginLintFile") else {
        print("Could not find SwiftLint plugin entry point")
        return []
    }

    typealias FunctionType = @convention(c) (String) -> Data
    let swiftlintPluginLintFile = unsafeBitCast(symbol, to: FunctionType.self)
    let result = swiftlintPluginLintFile(file)
    if result.isEmpty {
        return []
    }

    let payload = try JSONDecoder().decode(SwiftLintPluginLintResult.self, from: result)
    return payload.violations.map {
        StyleViolation(
            ruleIdentifier: $0.ruleIdentifier,
            ruleDescription: $0.ruleDescription,
            ruleName: $0.ruleName,
            severity: .init(rawValue: $0.severity.rawValue)!,
            location: Location(
                file: $0.location.file,
                line: $0.location.line,
                character: $0.location.character
            ),
            reason: $0.reason
        )
    }
}
