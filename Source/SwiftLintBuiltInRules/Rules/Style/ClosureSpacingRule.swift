import SwiftSyntax

@SwiftSyntaxRule(explicitRewriter: true, optIn: true)
struct ClosureSpacingRule: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "closure_spacing",
        name: "Closure Spacing",
        description: "Closure expressions should have a single space inside each brace",
        kind: .style,
        nonTriggeringExamples: [
            Example("[].map ({ $0.description })"),
            Example("[].filter { $0.contains(location) }"),
            Example("extension UITableViewCell: ReusableView { }"),
            Example("extension UITableViewCell: ReusableView {}"),
            Example(#"let r = /\{\}/"#, excludeFromDocumentation: true),
            Example("""
            var tapped: (UITapGestureRecognizer) -> Void = { _ in /* no-op */ }
            """, excludeFromDocumentation: true),
            Example("""
            let test1 = func1(arg: { /* do nothing */ })
            let test2 = func1 { /* do nothing */ }
            """, excludeFromDocumentation: true),
        ],
        triggeringExamples: [
            Example("[].filter↓{ $0.contains(location) }"),
            Example("[].filter(↓{$0.contains(location)})"),
            Example("[].map(↓{$0})"),
            Example("(↓{each in return result.contains(where: ↓{e in return e}) }).count"),
            Example("filter ↓{ sorted ↓{ $0 < $1}}"),
            Example("""
            var tapped: (UITapGestureRecognizer) -> Void = ↓{ _ in /* no-op */  }
            """, excludeFromDocumentation: true),
        ],
        corrections: [
            Example("[].filter(↓{$0.contains(location) })"):
                Example("[].filter({ $0.contains(location) })"),
            Example("[].map(↓{$0})"):
                Example("[].map({ $0 })"),
            Example("filter ↓{sorted ↓{ $0 < $1}}"):
                Example("filter { sorted { $0 < $1 } }"),
            Example("(↓{each in return result.contains(where: ↓{e in return 0})}).count"):
                Example("({ each in return result.contains(where: { e in return 0 }) }).count"),
        ]
    )
}

private extension ClosureSpacingRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: ClosureExprSyntax) {
            if node.shouldCheckForClosureSpacingRule(locationConverter: locationConverter),
               node.violations.hasViolations {
                violations.append(node.positionAfterSkippingLeadingTrivia)
            }
        }
    }

    final class Rewriter: ViolationsSyntaxRewriter<ConfigurationType> {
        override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
            var node = node
            node.statements = visit(node.statements)

            guard node.shouldCheckForClosureSpacingRule(locationConverter: locationConverter) else {
                return super.visit(node)
            }

            let violations = node.violations
            if violations.leftBraceLeftSpace {
                node.leftBrace = node.leftBrace.with(\.leadingTrivia, .spaces(1))
            }
            if violations.leftBraceRightSpace {
                node.leftBrace = node.leftBrace.with(\.trailingTrivia, .spaces(1))
            }
            if violations.rightBraceLeftSpace {
                node.rightBrace = node.rightBrace.with(\.leadingTrivia, .spaces(1))
            }
            if violations.rightBraceRightSpace {
                node.rightBrace = node.rightBrace.with(\.trailingTrivia, .spaces(1))
            }
            if violations.hasViolations {
                correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
            }

            return super.visit(node)
        }
    }
}

// MARK: - Private Helpers

private struct ClosureSpacingRuleClosureViolations {
    let leftBraceLeftSpace: Bool
    let leftBraceRightSpace: Bool
    let rightBraceLeftSpace: Bool
    let rightBraceRightSpace: Bool

    var hasViolations: Bool {
        leftBraceLeftSpace ||
            leftBraceRightSpace ||
            rightBraceLeftSpace ||
            rightBraceRightSpace
    }
}

private extension ClosureExprSyntax {
    var violations: ClosureSpacingRuleClosureViolations {
        ClosureSpacingRuleClosureViolations(
            leftBraceLeftSpace: !leftBrace.hasSingleSpaceToItsLeft &&
                !leftBrace.hasAllowedNoSpaceLeftToken &&
                !leftBrace.hasLeadingNewline,
            leftBraceRightSpace: !leftBrace.hasSingleSpaceToItsRight,
            rightBraceLeftSpace: !rightBrace.hasSingleSpaceToItsLeft,
            rightBraceRightSpace: !rightBrace.hasSingleSpaceToItsRight &&
                !rightBrace.hasAllowedNoSpaceRightToken &&
                !rightBrace.hasTrailingLineComment
        )
    }

    func shouldCheckForClosureSpacingRule(locationConverter: SourceLocationConverter) -> Bool {
        guard parent?.is(PostfixOperatorExprSyntax.self) == false, // Workaround for Regex literals
              (rightBrace.position.utf8Offset - leftBrace.position.utf8Offset) > 1, // Allow '{}'
              case let startLine = startLocation(converter: locationConverter).line,
              case let endLine = endLocation(converter: locationConverter).line,
              startLine == endLine // Only check single-line closures
        else {
            return false
        }

        return true
    }
}

private extension TokenSyntax {
    var hasSingleSpaceToItsLeft: Bool {
        if case .spaces(1) = Array(leadingTrivia).last {
            return true
        }
        if let previousToken = previousToken(viewMode: .sourceAccurate),
                  case .spaces(1) = Array(previousToken.trailingTrivia).last {
            return true
        }
        return false
    }

    var hasSingleSpaceToItsRight: Bool {
        if case .spaces(1) = trailingTrivia.first {
            return true
        }
        if let nextToken = nextToken(viewMode: .sourceAccurate),
                  case .spaces(1) = nextToken.leadingTrivia.first {
            return true
        }
        return false
    }

    var hasLeadingNewline: Bool {
        leadingTrivia.contains { piece in
            if case .newlines = piece {
                return true
            }
            return false
        }
    }

    var hasTrailingLineComment: Bool {
        trailingTrivia.contains { piece in
            if case .lineComment = piece {
                return true
            }
            return false
        }
    }

    var hasAllowedNoSpaceLeftToken: Bool {
        let previousTokenKind = parent?.previousToken(viewMode: .sourceAccurate)?.tokenKind
        return previousTokenKind == .leftParen || previousTokenKind == .leftSquare
    }

    var hasAllowedNoSpaceRightToken: Bool {
        let allowedKinds = [
            TokenKind.colon,
            .comma,
            .endOfFile,
            .exclamationMark,
            .leftParen,
            .leftSquare,
            .period,
            .postfixQuestionMark,
            .rightParen,
            .rightSquare,
            .semicolon,
        ]
        if case .newlines = trailingTrivia.first {
            return true
        }
        if case .newlines = nextToken(viewMode: .sourceAccurate)?.leadingTrivia.first {
            return true
        }
        if let nextToken = nextToken(viewMode: .sourceAccurate),
                  allowedKinds.contains(nextToken.tokenKind) {
            return true
        }
        return false
    }
}
