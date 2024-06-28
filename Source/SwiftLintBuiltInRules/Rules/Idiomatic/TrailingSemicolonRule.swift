import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct TrailingSemicolonRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "trailing_semicolon",
        name: "Trailing Semicolon",
        description: "Lines should not have trailing semicolons",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("let a = 0"),
            Example("let a = 0; let b = 0"),
        ],
        triggeringExamples: [
            Example("let a = 0↓;\n"),
            Example("let a = 0↓;\nlet b = 1"),
            Example("let a = 0↓; // a comment\n"),
        ],
        corrections: [
            Example("let a = 0↓;\n"): Example("let a = 0\n"),
            Example("let a = 0↓;\nlet b = 1"): Example("let a = 0\nlet b = 1"),
            Example("let foo = 12↓;  // comment\n"): Example("let foo = 12  // comment\n"),
        ]
    )
}

private extension TrailingSemicolonRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: TokenSyntax) {
            if node.isTrailingSemicolon {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: TokenSyntax) -> TokenSyntax {
            guard node.isTrailingSemicolon else {
                return super.visit(node)
            }

            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
            return .unknown("").with(\.trailingTrivia, node.trailingTrivia)
        }
    }
}

private extension TokenSyntax {
    var isTrailingSemicolon: Bool {
        tokenKind == .semicolon &&
            (
                trailingTrivia.containsNewlines() ||
                    (nextToken(viewMode: .sourceAccurate)?.leadingTrivia.containsNewlines() == true)
            )
    }
}
