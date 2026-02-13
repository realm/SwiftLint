@testable import SwiftLintBuiltInRules
import TestHelpers

final class ConditionalReturnsOnNewlineRuleTests: SwiftLintTestCase {
    func testConditionalReturnsOnNewlineWithIfOnly() {
        // Test with `if_only` set to true
        // guard statements should not trigger or be corrected
        let nonTriggeringExamples = [
            Example("guard true else {\n return true\n}"),
            Example("guard true,\n let x = true else {\n return true\n}"),
            Example("if true else {\n return true\n}"),
            Example("if true,\n let x = true else {\n return true\n}"),
            Example("if textField.returnKeyType == .Next {"),
            Example("if true { // return }"),
            Example("/*if true { */ return }"),
            Example("guard true else { return }"),
        ]
        let triggeringExamples = [
            Example("↓if true { return }"),
            Example("↓if true { break } else { return }"),
            Example("↓if true { break } else {       return }"),
            Example("↓if true { return \"YES\" } else { return \"NO\" }"),
        ]
        // Only include `if` corrections - guard corrections should not apply with if_only
        let corrections = [
            Example("↓if true { return }"): Example("if true {\n    return\n}"),
            Example("↓if true { break } else { return }"):
                Example("if true { break } else {\n    return\n}"),
            Example("↓if true { return \"YES\" } else { return \"NO\" }"):
                Example("if true {\n    return \"YES\"\n} else { return \"NO\" }"),
        ]

        let description = ConditionalReturnsOnNewlineRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(corrections: corrections)

        verifyRule(description, ruleConfiguration: ["if_only": true])
    }
}
