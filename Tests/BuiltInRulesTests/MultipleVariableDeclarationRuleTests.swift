import SwiftLintCore
import SwiftSyntax
import XCTest

@testable import SwiftLintBuiltInRules

final class MultipleVariableDeclarationRuleTests: XCTestCase {
    func testNonTriggeringExamples() {
        // Test cases where the rule should NOT trigger
        let nonTriggeringExamples = [
            Example("let a = 1\nlet b = 2"), // valid: variables on separate lines
            Example("var x = 10\nvar y = 20"), // valid: variables on separate lines
            Example("""
                    var a = 1
                    let b = 2
                    """),
        ]
        let triggeringExamples = [
            Example("let a = 1; let b = 2"), // invalid: variables on the same line
            Example("var x = 10; var y = 20"), // invalid: variables on the same line
            // invalid: multiple declarations on the same line should trigger multiple violations
            Example("let a = 1; let b = 2; let c = 3 "),
            Example("""
                    let a = 1; var b = 2
                    """),
            Example("""
                    func testFunction() {
                        let a = 1; let b = 2
                        var x = 10; var y = 20
                    }
                    """),
        ]

        nonTriggeringExamples.forEach { example in
            XCTAssertFalse(violatesRule(example.code))
        }

        triggeringExamples.forEach { example in
            XCTAssertTrue(violatesRule(example.code))
        }
    }

    // MARK: - Helper method to check for rule violations
    private func violatesRule(_ code: String) -> Bool {
        let file = SwiftLintFile(contents: code)
        let rule = MultipleVariableDeclarationRule()
        return !rule.validate(file: file).isEmpty
    }
}
