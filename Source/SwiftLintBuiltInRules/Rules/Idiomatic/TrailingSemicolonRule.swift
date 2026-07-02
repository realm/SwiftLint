import SwiftLintCore
import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct TrailingSemicolonRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "trailing_semicolon",
        name: "Trailing Semicolon",
        description: "Lines should not have trailing semicolons",
        kind: .idiomatic,
        nonTriggeringExamples: #examples([
            "let a = 0",
            "let a = 0; let b = 0",
        ]),
        triggeringExamples: #examples([
            "let a = 0↓;\n",
            "let a = 0↓;\nlet b = 1",
            "let a = 0↓; // a comment\n",
        ]),
        corrections: #corrections([
            "let a = 0↓;\n": "let a = 0\n",
            "let a = 0↓;\nlet b = 1": "let a = 0\nlet b = 1",
            "let foo = 12↓;  // comment\n": "let foo = 12  // comment\n",
        ])
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
            numberOfCorrections += 1
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
