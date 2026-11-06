import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct SortedCollectionMembersRuleTests {
    @Test
    func verify() {
        verifyRule(SortedCollectionMembersRule.description, ruleConfiguration: [])
    }
}
