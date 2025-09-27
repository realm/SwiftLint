import Foundation
import SwiftLintCore
import Testing

public struct TemporaryWorkingDirectory: TestScoping, SuiteTrait, TestTrait {
    private var temporaryDirectoryPath: String {
        let result = URL(
            fileURLWithPath: NSTemporaryDirectory(),
            isDirectory: true
        ).path

        #if os(macOS)
            return "/private" + result
        #else
            return result
        #endif
    }

    public func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: () async throws -> Void
    ) async throws {
        try await WorkingDirectory(path: temporaryDirectoryPath).provideScope(
            for: test,
            testCase: testCase,
            performing: function
        )
    }
}

public extension Trait where Self == TemporaryWorkingDirectory {
    static var temporaryWorkingDirectory: Self { Self() }
}

public struct WorkingDirectory: TestScoping, SuiteTrait, TestTrait {
    fileprivate let path: String

    public func provideScope(
        for _: Test,
        testCase _: Test.Case?,
        performing function: () async throws -> Void
    ) async throws {
        let previousDirectory = FileManager.default.currentDirectoryPath
        #expect(FileManager.default.changeCurrentDirectoryPath(path))
        try await function()
        #expect(FileManager.default.changeCurrentDirectoryPath(previousDirectory))
    }
}

public extension Trait where Self == WorkingDirectory {
    static func workingDirectory(_ path: @autoclosure () -> String) -> Self { Self(path: path()) }
}

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
