import SwiftSyntax

public struct EmptyStringRule: ConfigurationProviderRule, OptInRule, SwiftSyntaxRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "empty_string",
        name: "Empty String",
        description: "Prefer checking `isEmpty` over comparing `string` to an empty string literal.",
        kind: .performance,
        nonTriggeringExamples: [
            Example("myString.isEmpty"),
            Example("!myString.isEmpty"),
            Example("\"\"\"\nfoo==\n\"\"\"")
        ],
        triggeringExamples: [
            Example(#"myString↓ == """#),
            Example(#"myString↓ != """#),
            Example(#"myString↓=="""#),
            Example(##"myString↓ == #""#"##),
            Example(###"myString↓ == ##""##"###)
        ]
    )

    public func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor? {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension EmptyStringRule {
    final class Visitor: SyntaxVisitor, ViolationsSyntaxVisitor {
        private(set) var violationPositions: [AbsolutePosition] = []

        override func visitPost(_ node: StringLiteralExprSyntax) {
            guard
                // Empty string literal: `""`, `#""#`, etc.
                node.segments.count == 1 && node.segments.first?.contentLength == .zero,
                let previousToken = node.previousToken,
                // On the rhs of an `==` or `!=` operator
                previousToken.tokenKind.isEqualityComparison,
                let violationPosition = previousToken.previousToken?.endPositionBeforeTrailingTrivia
            else {
                return
            }

            violationPositions.append(violationPosition)
        }
    }
}

private extension TokenKind {
    var isEqualityComparison: Bool {
        self == .spacedBinaryOperator("==") ||
            self == .spacedBinaryOperator("!=") ||
            self == .unspacedBinaryOperator("==")
    }
}
