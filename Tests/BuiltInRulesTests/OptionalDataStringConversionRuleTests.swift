@testable import SwiftLintBuiltInRules
import TestHelpers

final class OptionalDataStringConversionRuleTests: SwiftLintTestCase {
    func testIncludeBareInit() {
        let nonTriggeringExamples = OptionalDataStringConversionRule.description.nonTriggeringExamples
            .filter { !$0.code.contains(".init") }

        let triggeringExamples =
            OptionalDataStringConversionRule.description.triggeringExamples + [
                Example("let text: String = ↓.init(decoding: data, as: UTF8.self)"),
            ]

        let description = OptionalDataStringConversionRule.description
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["include_bare_init": true])
    }
}
