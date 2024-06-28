import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true)
struct ClosingBraceRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "closing_brace",
        name: "Closing Brace Spacing",
        description: "Closing brace with closing parenthesis should not have any whitespaces in the middle",
        kind: .style,
        nonTriggeringExamples: [
            Example("[].map({ })"),
            Example("[].map(\n  { }\n)"),
        ],
        triggeringExamples: [
            Example("[].map({ ↓} )"),
            Example("[].map({ ↓}\t)"),
        ],
        corrections: [
            Example("[].map({ ↓} )"): Example("[].map({ })")
        ]
    )
}

private extension ClosingBraceRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: TokenSyntax) {
            if node.hasClosingBraceViolation {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: TokenSyntax) -> TokenSyntax {
            guard node.hasClosingBraceViolation else {
                return super.visit(node)
            }
            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
            return super.visit(node.with(\.trailingTrivia, Trivia()))
        }
    }
}

private extension TokenSyntax {
    var hasClosingBraceViolation: Bool {
        guard
            tokenKind == .rightBrace,
            let nextToken = nextToken(viewMode: .sourceAccurate),
            nextToken.tokenKind == .rightParen
        else {
            return false
        }

        let isImmediatelyNext = positionAfterSkippingLeadingTrivia
            == nextToken.positionAfterSkippingLeadingTrivia - SourceLength(utf8Length: 1)
        if isImmediatelyNext || nextToken.hasLeadingNewline {
            return false
        }
        return true
    }

    private var hasLeadingNewline: Bool {
        leadingTrivia.contains { piece in
            if case .newlines = piece {
                return true
            }
            return false
        }
    }
}
