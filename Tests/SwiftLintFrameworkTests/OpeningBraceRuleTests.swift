import SwiftLintFramework
import XCTest

class OpeningBraceRuleTests: XCTestCase {
    func testOpeningBraceRule() {
        verifyRule(OpeningBraceRule.description)
    }

    func testMultilineFuncWhenAddedToExcluded() {
        let baseDescription = OpeningBraceRule.description

        let triggeringExamplesToRemove = [
            "func abc(\n\ta: Int,\n\tb: Int)\n↓{ }"
        ]

        let nonTriggeringExamples = baseDescription.nonTriggeringExamples +
            triggeringExamplesToRemove.map { $0.replacingOccurrences(of: "↓", with: "") }

        let triggeringExamples = baseDescription.triggeringExamples
            .filter { !triggeringExamplesToRemove.contains($0) }

        let description = baseDescription.with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration:
            ["first_line_excluding_regex": "if|guard|while|func \\w+\\("]
        )
    }

    func testMultilineIfWhenRemovedFromExcluded() {
        let baseDescription = OpeningBraceRule.description

        let nonTriggeringExamplesToRemove = [
            "if\n\tlet a = b,\n\tlet c = d\n\twhere a == c\n{ }"
        ]

        let newTriggeringExamples = [
            "if\n\tlet a = b,\n\tlet c = d\n\twhere a == c\n↓{ }"
        ]

        let nonTriggeringExamples = baseDescription.nonTriggeringExamples
            .filter { !nonTriggeringExamplesToRemove.contains($0) }

        let triggeringExamples = baseDescription.triggeringExamples
            + newTriggeringExamples

        let description = baseDescription
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)

        verifyRule(description, ruleConfiguration:
            ["first_line_excluding_regex": "guard|while"]
        )
    }
}
