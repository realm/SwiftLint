@testable import SwiftLintBuiltInRules

class NoUnnecessarySpacesRuleTests: SwiftLintTestCase {
    func testNoUnnecessarySpacesRule() {
        let description = NoUnnecessarySpacesRule.description
        verifyRule(description)
    }
}
