@testable import SwiftLintBuiltInRules

class FunctionArgumentsSpacingRuleTests: SwiftLintTestCase {
    func test() {
        
        let nonTriggeringExamples = [
            Example("makeGenerator(style)")
        ]
        let triggeringExamples = [
            Example("makeGenerator( ↓style)")
        ]
        let description = FunctionArgumentsSpacingRule.description.with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)
        
        verifyRule(description)
        
    }
}
