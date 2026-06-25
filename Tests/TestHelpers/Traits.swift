@preconcurrency import Foundation
import SwiftLintFramework
import Testing

public struct RuleRegisterer: TestScoping, SuiteTrait, TestTrait {
    public func provideScope(
        for _: Test,
        testCase _: Test.Case?,
        performing function: () async throws -> Void
    ) async throws {
        RuleRegistry.registerAllRulesOnce()
        try await function()
    }
}

public extension Trait where Self == RuleRegisterer {
    static var rulesRegistered: Self { Self() }
}

public struct SourceKitRequestsWithoutRule: TestScoping, SuiteTrait, TestTrait {
    public func provideScope(
        for _: Test,
        testCase _: Test.Case?,
        performing function: () async throws -> Void
    ) async throws {
        try await CurrentRule.$allowSourceKitRequestWithoutRule.withValue(true) {
            try await function()
        }
    }
}

public extension Trait where Self == SourceKitRequestsWithoutRule {
    static var sourceKitRequestsWithoutRule: Self { Self() }
}

public struct DisableParserDiagnosticsInTests: TestScoping, SuiteTrait, TestTrait {
    fileprivate let value: Bool

    public func provideScope(
        for _: Test,
        testCase _: Test.Case?,
        performing function: () async throws -> Void
    ) async throws {
        try await $parserDiagnosticsDisabledForTests.withValue(!value) {
            try await function()
        }
    }
}

public extension Trait where Self == DisableParserDiagnosticsInTests {
    static func parserDiagnosticsEnabled(_ value: Bool) -> Self { Self(value: value) }
}

/// A test trait that runs each test with an isolated, task-local working directory allowing tests to run
/// fully in parallel without interfering with each other.
public struct TestDirectory: TestScoping, SuiteTrait, TestTrait {
    fileprivate enum Kind {
        case temporary(fixturePath: URL?)
        case fixed(URL)
    }

    fileprivate let kind: Kind

    public func provideScope(
        for _: Test,
        testCase _: Test.Case?,
        performing function: () async throws -> Void
    ) async throws {
        switch kind {
        case .temporary(let fixturePath):
            let tempDir: URL
            if let fixturePath {
                guard fixturePath.isDirectory else {
                    queuedFatalError("Fixture path '\(String(describing: fixturePath))' must be a directory")
                }
                let lastFixtureComponent = fixturePath.lastPathComponent
                tempDir = URL.temporaryDirectory.appending(
                    path: UUID().uuidString + "-\(lastFixtureComponent)",
                    directoryHint: .isDirectory
                )
                try FileManager.default.copyItem(at: fixturePath, to: tempDir)
            } else {
                tempDir = URL.temporaryDirectory.appending(
                    path: UUID().uuidString,
                    directoryHint: .isDirectory
                )
                try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
            }
            defer {
                do {
                    try FileManager.default.removeItem(at: tempDir)
                } catch {
                    queuedFatalError("Failed to remove temporary directory '\(tempDir)': \(error)")
                }
            }
            try await CurrentWorkingDirectory.$url.withValue(tempDir) {
                try await function()
            }
        case .fixed(let url):
            try await CurrentWorkingDirectory.$url.withValue(url) {
                try await function()
            }
        }
    }
}

public extension Trait where Self == TestDirectory {
    /// Runs the test with `URL.cwd` pointing to a unique, freshly created temporary directory.
    /// The directory is deleted after the test finishes.
    static var temporaryDirectory: Self { Self(kind: .temporary(fixturePath: nil)) }

    /// Runs the test with `URL.cwd` pointing to a unique, freshly created temporary directory initialized
    /// with the contents of the given fixture directory. The temporary directory is deleted after the test finishes.
    static func temporaryDirectory(withFixture fixturePath: URL) -> Self {
        Self(kind: .temporary(fixturePath: fixturePath))
    }

    /// Runs the test with `URL.cwd` set to the given `url` without modifying the process-wide
    /// working directory.
    static func workingDirectory(_ url: URL) -> Self { Self(kind: .fixed(url)) }
}
