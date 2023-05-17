import SwiftSyntax

struct EmptyStringRule: ConfigurationProviderRule, OptInRule, SwiftSyntaxRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "empty_string",
        name: "Empty String",
        description: "Prefer checking `isEmpty` over comparing `string` to an empty string literal",
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

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension EmptyStringRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: StringLiteralExprSyntax) {
            guard
                // Empty string literal: `""`, `#""#`, etc.
                node.segments.onlyElement?.contentLength == .zero,
                let previousToken = node.previousToken(viewMode: .sourceAccurate),
                // On the rhs of an `==` or `!=` operator
                previousToken.tokenKind.isEqualityComparison,
                let secondPreviousToken = previousToken.previousToken(viewMode: .sourceAccurate)
            else {
                return
            }

            let violationPosition = secondPreviousToken.endPositionBeforeTrailingTrivia
            violations.append(violationPosition)
        }
    }
}
