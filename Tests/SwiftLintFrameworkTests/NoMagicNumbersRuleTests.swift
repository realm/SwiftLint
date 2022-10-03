import SwiftLintFramework
import XCTest

class NoMagicNumbersRuleTests: XCTestCase {
    func testNoMagicNumbers() {
        let nonTriggeringExamples = [
            Example("var foo = 123"),
            Example("static let bar = 0.123"),
            Example("array[1]"),
            Example("array[0]"),
            Example("let foo = 1_000.000_01"),
            Example("// array[1337]"),
            Example("baz(\"9999\")"),
            Example("""
func foo() {
    let x = 2
    let y = [0, 0, 0][x]
}
"""),
            Example(
"""
class A {
    var foo = 132
    static let bar = 0.98
}
""")
        ]
        let triggeringExamples = [
            Example("foo(123)"),
            Example("bar(1_000.005_01)"),
            Example("Color.primary.opacity(isAnimate ? 0.1 : 1.0)"),
            Example("array[42]"),
            Example("let box = array[1337]")
        ]

        let description = NoMagicNumbersRule.description
            .with(triggeringExamples: triggeringExamples)
            .with(nonTriggeringExamples: nonTriggeringExamples)

        verifyRule(description)
    }
}
