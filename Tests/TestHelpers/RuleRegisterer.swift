import SwiftLintFramework
import Testing

public struct RuleRegisterer: TestScoping, SuiteTrait, TestTrait {
    public func provideScope(
        for test: Test,
        testCase: Test.Case?,
        performing function: () async throws -> Void
    ) async throws {
        RuleRegistry.registerAllRulesOnce()
        try await function()
    }
}

public extension Trait where Self == RuleRegisterer {
    static var rulesRegistered: Self { Self() }
}
