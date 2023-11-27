@testable import SwiftLintBuiltInRules

class FunctionArgumentsSpacingRuleTests: SwiftLintTestCase {
    func testFunctionArgumentsSpacingRule() {
        let description = FunctionArgumentsSpacingRule.description
        verifyRule(description)
    }
}
