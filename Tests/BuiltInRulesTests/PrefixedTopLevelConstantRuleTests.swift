import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct PrefixedTopLevelConstantRuleTests {
    @Test
    func privateOnly() {
        let triggeringExamples = #examples([
            "private let ↓Foo = 20.0",
            "fileprivate let ↓foo = 20.0",
        ])
        let nonTriggeringExamples = #examples([
            "let Foo = 20.0",
            "internal let Foo = \"Foo\"",
            "public let Foo = 20.0",
        ])

        let description = PrefixedTopLevelConstantRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["only_private": true])
    }
}
