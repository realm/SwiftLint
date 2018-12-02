@testable import SwiftLintFramework
import XCTest

class ConditionalReturnsOnNewlineRuleTests: XCTestCase {
    func testConditionalReturnsOnNewlineWithDefaultConfiguration() {
        // Test with default parameters
        verifyRule(ConditionalReturnsOnNewlineRule.description)
    }

    func testConditionalReturnsOnNewlineWithIfOnly() {
        // Test with `if_only` set to true
        let nonTriggeringExamples = [
            "guard true else {\n return true\n}",
            "guard true,\n let x = true else {\n return true\n}",
            "if true else {\n return true\n}",
            "if true,\n let x = true else {\n return true\n}",
            "if textField.returnKeyType == .Next {",
            "if true { // return }",
            "/*if true { */ return }",
            "guard true else { return }"
        ]
        let triggeringExamples = [
            "↓if true { return }",
            "↓if true { break } else { return }",
            "↓if true { break } else {       return }",
            "↓if true { return \"YES\" } else { return \"NO\" }"
        ]

        let description = ConditionalReturnsOnNewlineRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["if_only": true])
    }
}
