import SwiftSyntax

public struct NoMagicNumbersRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    public init() {}

    public var configuration = SeverityConfiguration(.warning)

    private static let functionExample = Example("""
func foo() {
    let x: Int = 2
    let y = 3
    let vector = [x, y, 0]
}
""")

    private static let classExample = Example("""
class A {
    var foo: Double = 132
    static let bar: Double = 0.98
}
""")

    private static let availableExample = Example("""
@available(iOS 13, *)
func version() {
    if #available(iOS 13, OSX 10.10, *) {
        return
    }
}
""")

    public static let description = RuleDescription(
        identifier: "no_magic_numbers",
        name: "No Magic Numbers",
        description: "‘Magic numbers’ should be replaced by named constants.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("0.123"),
            Example("var foo = 123"),
            Example("static let bar: Double = 0.123"),
            Example("array[0] + array[1]"),
            Example("let foo = 1_000.000_01"),
            Example("// array[1337]"),
            Example("baz(\"9999\")"),
            functionExample,
            classExample,
            availableExample
        ],
        triggeringExamples: [
            Example("foo(123)"),
            Example("bar(1_000.005_01)"),
            Example("array[42]"),
            Example("let box = array[12 + 14]"),
            Example("Color.primary.opacity(isAnimate ? 0.1 : 1.5)")
        ]
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension NoMagicNumbersRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: FloatLiteralExprSyntax) {
            if node.floatingDigits.isMagicNumber {
                self.violations.append(node.floatingDigits.positionAfterSkippingLeadingTrivia)
            }
        }

        override func visitPost(_ node: IntegerLiteralExprSyntax) {
            if node.digits.isMagicNumber {
                self.violations.append(node.digits.positionAfterSkippingLeadingTrivia)
            }
        }
    }
}

private extension TokenSyntax {
    var isMagicNumber: Bool {
        let numerStr = withoutTrivia().text.replacingOccurrences(of: "_", with: "")

        guard let number = Double(numerStr),
              ![0, 1, -1].contains(number),
              let parentToken = parent?.parent,
              !parentToken.is(InitializerClauseSyntax.self),
              !parentToken.is(CodeBlockItemSyntax.self) else {
            return false
        }
        return true
    }
}
