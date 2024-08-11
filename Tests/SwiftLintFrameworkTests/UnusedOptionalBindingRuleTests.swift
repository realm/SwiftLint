@testable import SwiftLintBuiltInRules

final class UnusedOptionalBindingRuleTests: SwiftLintTestCase {
    func testDefaultConfiguration() async {
        let baseDescription = UnusedOptionalBindingRule.description
        let triggeringExamples = baseDescription.triggeringExamples + [
            Example("guard let _ = try? alwaysThrows() else { return }")
        ]

        let description = baseDescription.with(triggeringExamples: triggeringExamples)
        await verifyRule(description)
    }

    func testIgnoreOptionalTryEnabled() async {
        // Perform additional tests with the ignore_optional_try settings enabled.
        let baseDescription = UnusedOptionalBindingRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [
            Example("guard let _ = try? alwaysThrows() else { return }")
        ]

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
        await verifyRule(description, ruleConfiguration: ["ignore_optional_try": true])
    }
}
