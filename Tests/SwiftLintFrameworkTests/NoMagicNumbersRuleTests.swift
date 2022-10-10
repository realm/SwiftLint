import SwiftLintFramework
import XCTest

class NoMagicNumbersRuleTests: XCTestCase {
    private let functionExample = Example("""
func foo() {
    let x: Int = 2
    let y = 3
    let vector = [x, y, 0]
}
""")

    private let classExample = Example("""
class A {
    var foo: Double = 132
    static let bar: Double = 0.98
}
""")

    private let availableExample = Example("""
@available(iOS 13, *)
func version() {
    if #available(iOS 13, OSX 10.10, *) {
        return
    }
}
""")

    func testNoMagicNumbers() {
        let nonTriggeringExamples = [
            Example("0.123"),
            Example("var foo = 123"),
            Example("static let bar = 0.123"),
            Example("static let bar: Double = 0.123"),
            Example("array[1]"),
            Example("array[0]"),
            Example("let foo = 1_000.000_01"),
            Example("// array[1337]"),
            Example("baz(\"9999\")"),
            functionExample,
            classExample,
            availableExample
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
