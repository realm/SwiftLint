@testable import SwiftLintBuiltInRules

class FunctionArgumentsSpacingRuleTests: SwiftLintTestCase {
    func test() {
        let nonTriggeringExamples = [
            Example("makeGenerator()"),
            Example("makeGenerator(style)"),
            Example("makeGenerator(true, false)"),
        ]
        let triggeringExamples = [
            Example("makeGenerator(↓ style)"),
            Example("makeGenerator(style ↓)"),
            Example("makeGenerator(↓ style ↓)"),
            Example("makeGenerator(↓ offset: 0, limit: 0)"),
            Example("makeGenerator(offset: 0, limit: 0 ↓)"),
            Example("makeGenerator(↓ 1, 2, 3 ↓)")
        ]
        let description = FunctionArgumentsSpacingRule.description.with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)
        
        verifyRule(description)
    }
}
