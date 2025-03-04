import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true, optIn: true)
struct MultipleStatementsDeclarationRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "multiple_statements_declaration",
        name: "Multiple Statements Declaration",
        description: "Statements should not be on the same line",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example(
                """
                    let a = 1;
                    let b = 2;
                """
                ),
            Example(
                """
                    var x = 10
                    var y = 20;
                """
            ),
            Example(
                """
                    let x = 10;
                    var y = 20
                """
            ),
            Example(
                """
                    let a = 1;
                    return a
                """
            ),
            Example(
                """
                    if b { return };  
                    let a = 1
                """
            ),
        ],
        triggeringExamples: [
            Example("let a = 1; return a"),
            Example("if b { return }; let a = 1"),
            Example("if b { return }; if c { return }"),
            Example("let a = 1; let b = 2; let c = 0"),
            Example("var x = 10; var y = 20"),
            Example("let x = 10; var y = 20"),
        ],
        corrections: [
            Example("let a = 0↓; let b = 0"): Example("let a = 0\nlet b = 0"),
            Example("let a = 0↓; let b = 0↓; let c = 0"): Example("let a = 0\nlet b = 0\nlet c = 0"),
            Example("let a = 0↓; print(\"Hello\")"): Example("let a = 0\nprint(\"Hello\")"),
        ]
    )
}

private extension MultipleStatementsDeclarationRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: TokenSyntax) {
            if node.isThereStatementAfterSemicolon {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: TokenSyntax) -> TokenSyntax {
            guard node.isThereStatementAfterSemicolon else {
                return super.visit(node)
            }

            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
            
            let newNode = TokenSyntax(
                .unknown(""),
                leadingTrivia: node.leadingTrivia,
                trailingTrivia: .newlines(1),
                presence: .present
            )
            return super.visit(newNode)
        }
    }

}

private extension TokenSyntax {
    var isThereStatementAfterSemicolon: Bool {
        guard tokenKind == .semicolon, !trailingTrivia.isEmpty else { return false }

        if let nextToken = nextToken(viewMode: .sourceAccurate),
           isFollowedOnlyByWhitespaceOrNewline {
            return nextToken.leadingTrivia.containsNewlines() == false
        } else {
            return true
        }
    }
    
    var isFollowedOnlyByWhitespaceOrNewline: Bool {
        guard let nextToken = nextToken(viewMode: .sourceAccurate),
              !nextToken.trailingTrivia.isEmpty else {
            return true
        }
        return nextToken.leadingTrivia.allSatisfy { $0.isWhitespaceOrNewline }
    }
}

private extension TriviaPiece {
    var isWhitespaceOrNewline: Bool {
        switch self {
        case .spaces, .tabs, .newlines, .carriageReturns, .carriageReturnLineFeeds:
            return true
        default:
            return false
        }
    }
}
