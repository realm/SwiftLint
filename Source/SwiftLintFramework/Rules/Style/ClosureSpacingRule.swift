import SwiftSyntax

// MARK: - ClosureSpacingRule

struct ClosureSpacingRule: SwiftSyntaxCorrectableRule, ConfigurationProviderRule, OptInRule {
    var configuration = SeverityConfiguration(.warning)

    init() {}

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
            """, excludeFromDocumentation: true)
        ],
        triggeringExamples: [
            Example("[].filter↓{ $0.contains(location) }"),
            Example("[].filter(↓{$0.contains(location)})"),
            Example("[].map(↓{$0})"),
            Example("(↓{each in return result.contains(where: ↓{e in return e}) }).count"),
            Example("filter ↓{ sorted ↓{ $0 < $1}}"),
            Example("""
            var tapped: (UITapGestureRecognizer) -> Void = ↓{ _ in /* no-op */  }
            """, excludeFromDocumentation: true)
        ],
        corrections: [
            Example("[].filter(↓{$0.contains(location) })"):
                Example("[].filter({ $0.contains(location) })"),
            Example("[].map(↓{$0})"):
                Example("[].map({ $0 })"),
            Example("filter ↓{sorted ↓{ $0 < $1}}"):
                Example("filter { sorted { $0 < $1 } }"),
            Example("(↓{each in return result.contains(where: ↓{e in return 0})}).count"):
                Example("({ each in return result.contains(where: { e in return 0 }) }).count")
        ]
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        ClosureSpacingRuleVisitor(locationConverter: file.locationConverter)
    }

    func makeRewriter(file: SwiftLintFile) -> ViolationsSyntaxRewriter? {
        ClosureSpacingRuleRewriter(
            locationConverter: file.locationConverter,
            disabledRegions: disabledRegions(file: file)
        )
    }
}

// MARK: - ClosureSpacingRuleVisitor

private final class ClosureSpacingRuleVisitor: ViolationsSyntaxVisitor {
    let locationConverter: SourceLocationConverter

    init(locationConverter: SourceLocationConverter) {
        self.locationConverter = locationConverter
        super.init(viewMode: .sourceAccurate)
    }

    override func visitPost(_ node: ClosureExprSyntax) {
        if node.shouldCheckForClosureSpacingRule(locationConverter: locationConverter),
           node.violations.hasViolations {
            violations.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}

// MARK: - ClosureSpacingRuleRewriter

private final class ClosureSpacingRuleRewriter: SyntaxRewriter, ViolationsSyntaxRewriter {
    private(set) var correctionPositions: [AbsolutePosition] = []
    let locationConverter: SourceLocationConverter
    let disabledRegions: [SourceRange]

    init(locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
        self.locationConverter = locationConverter
        self.disabledRegions = disabledRegions
    }

    override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
        var node = node
        node.statements = visit(node.statements)

        guard
            !node.isContainedIn(regions: disabledRegions, locationConverter: locationConverter),
            node.shouldCheckForClosureSpacingRule(locationConverter: locationConverter)
        else {
            return super.visit(node)
        }

        let violations = node.violations
        if violations.leftBraceLeftSpace {
            node.leftBrace = node.leftBrace.withLeadingTrivia(.spaces(1))
        }
        if violations.leftBraceRightSpace {
            node.leftBrace = node.leftBrace.withTrailingTrivia(.spaces(1))
        }
        if violations.rightBraceLeftSpace {
            node.rightBrace = node.rightBrace.withLeadingTrivia(.spaces(1))
        }
        if violations.rightBraceRightSpace {
            node.rightBrace = node.rightBrace.withTrailingTrivia(.spaces(1))
        }
        if violations.hasViolations {
            correctionPositions.append(node.positionAfterSkippingLeadingTrivia)
        }

        return super.visit(node)
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
        guard parent?.is(PostfixUnaryExprSyntax.self) == false, // Workaround for Regex literals
              (rightBrace.position.utf8Offset - leftBrace.position.utf8Offset) > 1, // Allow '{}'
              let startLine = startLocation(converter: locationConverter).line,
              let endLine = endLocation(converter: locationConverter).line,
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
        } else if let previousToken, case .spaces(1) = Array(previousToken.trailingTrivia).last {
            return true
        } else {
            return false
        }
    }

    var hasSingleSpaceToItsRight: Bool {
        if case .spaces(1) = trailingTrivia.first {
            return true
        } else if let nextToken, case .spaces(1) = nextToken.leadingTrivia.first {
            return true
        } else {
            return false
        }
    }

    var hasLeadingNewline: Bool {
        leadingTrivia.contains { piece in
            if case .newlines = piece {
                return true
            } else {
                return false
            }
        }
    }

    var hasTrailingLineComment: Bool {
        trailingTrivia.contains { piece in
            if case .lineComment = piece {
                return true
            } else {
                return false
            }
        }
    }

    var hasAllowedNoSpaceLeftToken: Bool {
        let previousTokenKind = parent?.previousToken?.tokenKind
        return previousTokenKind == .leftParen || previousTokenKind == .leftSquareBracket
    }

    var hasAllowedNoSpaceRightToken: Bool {
        let allowedKinds = [
            TokenKind.colon,
            .comma,
            .eof,
            .exclamationMark,
            .leftParen,
            .leftSquareBracket,
            .period,
            .postfixQuestionMark,
            .rightParen,
            .rightSquareBracket,
            .semicolon
        ]
        if case .newlines = trailingTrivia.first {
            return true
        } else if case .newlines = nextToken?.leadingTrivia.first {
            return true
        } else if let nextToken = nextToken, allowedKinds.contains(nextToken.tokenKind) {
            return true
        } else {
            return false
        }
    }
}
