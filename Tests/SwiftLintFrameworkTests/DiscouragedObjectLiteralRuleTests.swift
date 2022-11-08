@testable import SwiftLintFramework

class DiscouragedObjectLiteralRuleTests: SwiftLintTestCase {
    func testWithImageLiteral() {
        let baseDescription = DiscouragedObjectLiteralRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [
            Example("let color = #colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)")
        ]
        let triggeringExamples = [
            Example("let image = ↓#imageLiteral(resourceName: \"image.jpg\")")
        ]

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples,
                                               triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["image_literal": true, "color_literal": false])
    }

    func testWithColorLiteral() {
        let baseDescription = DiscouragedObjectLiteralRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [
            Example("let image = #imageLiteral(resourceName: \"image.jpg\")")
        ]
        let triggeringExamples = [
            Example("let color = ↓#colorLiteral(red: 0.9607843161, green: 0.7058823705, blue: 0.200000003, alpha: 1)")
        ]

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples,
                                               triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration: ["image_literal": false, "color_literal": true])
    }
}
