@testable import SwiftLintBuiltInRules

class TrailingClosureRuleTests: SwiftLintTestCase {
    func testWithOnlySingleMutedParameterEnabled() {
        let originalDescription = TrailingClosureRule.description
        let description = originalDescription
            .with(nonTriggeringExamples: originalDescription.nonTriggeringExamples + [
                Example("foo.reduce(0, combine: { $0 + 1 })"),
                Example("offsets.sorted(by: { $0.offset < $1.offset })"),
                Example("foo.something(0, { $0 + 1 })")
            ])
            .with(triggeringExamples: [Example("foo.map({ $0 + 1 })")])

        verifyRule(description, ruleConfiguration: ["only_single_muted_parameter": true])
    }
}
