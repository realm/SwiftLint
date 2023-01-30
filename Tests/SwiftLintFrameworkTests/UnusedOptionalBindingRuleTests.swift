@testable import SwiftLintFramework
import XCTest

class UnusedOptionalBindingRuleTests: XCTestCase {
    func testDefaultConfiguration() async throws {
        let baseDescription = UnusedOptionalBindingRule.description
        let triggeringExamples = baseDescription.triggeringExamples + [
            Example("guard let _ = try? alwaysThrows() else { return }")
        ]

        let description = baseDescription.with(triggeringExamples: triggeringExamples)
        try await verifyRule(description)
    }

    func testIgnoreOptionalTryEnabled() async throws {
        // Perform additional tests with the ignore_optional_try settings enabled.
        let baseDescription = UnusedOptionalBindingRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [
            Example("guard let _ = try? alwaysThrows() else { return }")
        ]

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
        try await verifyRule(description, ruleConfiguration: ["ignore_optional_try": true])
    }
}
