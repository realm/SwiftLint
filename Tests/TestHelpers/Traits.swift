import Foundation
import SwiftLintCore
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
