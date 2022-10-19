import SwiftSyntax

public struct NoMagicNumbersRule: SwiftSyntaxRule, OptInRule, ConfigurationProviderRule {
    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor()
    }

    public init() {}

    public init(configuration: Any) throws {}

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
}

private extension NoMagicNumbersRule {
    final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        var violationPositions: [AbsolutePosition] = []

        init() {
            super.init(viewMode: .sourceAccurate)
        }

        override func visitPost(_ node: FloatLiteralExprSyntax) {
            if let violation = violation(token: node.floatingDigits) {
                violationPositions.append(violation)
            }
        }

        override func visitPost(_ node: IntegerLiteralExprSyntax) {
            if let violation = violation(token: node.digits) {
                violationPositions.append(violation)
            }
        }

        func violation(token: TokenSyntax) -> AbsolutePosition? {
            let text = token.withoutTrivia().text.replacingOccurrences(of: "_", with: "")

            guard let number = Double(text), ![0, 1, -1].contains(number),
                    let parent = token.parent?.parent,
                    !parent.is(InitializerClauseSyntax.self),
                    !parent.is(CodeBlockItemSyntax.self) else {
                return nil
            }

            return token.positionAfterSkippingLeadingTrivia
        }
    }
}
