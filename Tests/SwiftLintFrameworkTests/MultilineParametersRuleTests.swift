import SwiftLintFramework
import XCTest

final class MultilineParametersRuleTests: XCTestCase {
    /// Tests the default behavior of this rule.
    func testWhenAllowsSingleLineIsTrue() {
        verifyRule(MultilineParametersRule.description)
    }

    /// Tests the behavior of this rule when configured to
    /// enforce all the parameters to be in different lines.
    func testWhenAllowsSingleLineIsFalse() {
        let triggeringExamples = [
            Example("func ↓foo(param1: Int, param2: Bool) { }"),
            Example("func ↓foo(param1: Int, param2: Bool, param3: [String]) { }")
        ]

        let nonTriggeringExamples = [
            Example("func foo() { }"),
            Example("func foo(param1: Int) { }"),
            Example("""
            protocol Foo {
                func foo(param1: Int,
                         param2: Bool,
                         param3: [String]) { }
            }
            """),
            Example("""
            protocol Foo {
                func foo(
                    param1: Int
                ) { }
            }
            """),
            Example("""
            protocol Foo {
                func foo(
                    param1: Int,
                    param2: Bool,
                    param3: [String]
                ) { }
            }
            """)
        ]

        let description = MultilineParametersRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description, ruleConfiguration: ["allows_single_line": false])
    }
}
