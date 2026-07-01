import SwiftLintCore
import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct DiscouragedObjectLiteralRuleTests {
    @Test
    func withImageLiteral() {
        let baseDescription = DiscouragedObjectLiteralRule.description
        let nonTriggeringExamples =
            baseDescription.nonTriggeringExamples + #examples([
                """
                    let color = #colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)
                    """,
            ])
        let triggeringExamples = #examples([
            "let image = ↓#imageLiteral(resourceName: \"image.jpg\")"
        ])

        let description = baseDescription.with(
            nonTriggeringExamples: nonTriggeringExamples,
            triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["image_literal": true, "color_literal": false])
    }

    @Test
    func withColorLiteral() {
        let baseDescription = DiscouragedObjectLiteralRule.description
        let nonTriggeringExamples =
            baseDescription.nonTriggeringExamples + #examples([
                "let image = #imageLiteral(resourceName: \"image.jpg\")"
            ])
        let triggeringExamples = #examples([
            "let color = ↓#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)"
        ])

        let description = baseDescription.with(
            nonTriggeringExamples: nonTriggeringExamples,
            triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["image_literal": false, "color_literal": true])
    }
}
