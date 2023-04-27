@testable import SwiftLintBuiltInRules

class UnusedOptionalBindingRuleTests: SwiftLintTestCase {
    func testDefaultConfiguration() {
        let baseDescription = UnusedOptionalBindingRule.description
        let triggeringExamples = baseDescription.triggeringExamples + [
            Example("guard let _ = try? alwaysThrows() else { return }")
        ]

        let description = baseDescription.with(triggeringExamples: triggeringExamples)
        verifyRule(description)
    }

    func testIgnoreOptionalTryEnabled() {
        // Perform additional tests with the ignore_optional_try settings enabled.
        let baseDescription = UnusedOptionalBindingRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [
            Example("guard let _ = try? alwaysThrows() else { return }")
        ]

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
        verifyRule(description, ruleConfiguration: ["ignore_optional_try": true])
    }
}
