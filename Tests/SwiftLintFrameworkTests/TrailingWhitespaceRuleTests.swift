@testable import SwiftLintFramework

class TrailingWhitespaceRuleTests: SwiftLintTestCase {
    func testWithIgnoresEmptyLinesEnabled() {
        // Perform additional tests with the ignores_empty_lines setting enabled.
        // The set of non-triggering examples is extended by a whitespace-indented empty line
        let baseDescription = TrailingWhitespaceRule.description
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples + [Example(" \n")]
        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description,
                   ruleConfiguration: ["ignores_empty_lines": true, "ignores_comments": true])
    }

    func testWithIgnoresCommentsDisabled() {
        // Perform additional tests with the ignores_comments settings disabled.
        let baseDescription = TrailingWhitespaceRule.description
        let triggeringComments = [
            Example("// \n"),
            Example("let name: String // \n")
        ]
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples
            .filter { !triggeringComments.contains($0) }
        let triggeringExamples = baseDescription.triggeringExamples + triggeringComments
        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
                                         .with(triggeringExamples: triggeringExamples)
        verifyRule(description,
                   ruleConfiguration: ["ignores_empty_lines": false, "ignores_comments": false],
                   commentDoesntViolate: false)
    }
}
