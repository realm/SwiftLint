import SourceKittenFramework
import SwiftSyntax

// MARK: - ClosureSpacingRule

public struct ClosureSpacingRule: CorrectableRule, ConfigurationProviderRule, OptInRule, SourceKitFreeRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "closure_spacing",
        name: "Closure Spacing",
        description: "Closure expressions should have a single space inside each brace.",
        kind: .style,
        nonTriggeringExamples: [
            Example("[].map ({ $0.description })"),
            Example("[].filter { $0.contains(location) }"),
            Example("extension UITableViewCell: ReusableView { }"),
            Example("extension UITableViewCell: ReusableView {}"),
            Example(#"let r = /\{\}/"#, excludeFromDocumentation: true)
        ],
        triggeringExamples: [
            Example("[].filter↓{ $0.contains(location) }"),
            Example("[].filter(↓{$0.contains(location)})"),
            Example("[].map(↓{$0})"),
            Example("(↓{each in return result.contains(where: ↓{e in return e}) }).count"),
            Example("filter ↓{ sorted ↓{ $0 < $1}}")
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

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        guard let locationConverter = file.locationConverter else {
            return []
        }

        return ClosureSpacingRuleVisitor(locationConverter: locationConverter)
            .walk(file: file, handler: \.sortedPositions)
            .map { position in
                StyleViolation(ruleDescription: Self.description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: ByteCount(position)))
            }
    }

    public func correct(file: SwiftLintFile) -> [Correction] {
        guard let locationConverter = file.locationConverter else {
            return []
        }

        let disabledRegions = file.regions()
            .filter { $0.isRuleDisabled(self) }
            .compactMap { $0.toSourceRange(locationConverter: locationConverter) }

        let rewriter = ClosureSpacingRuleRewriter(locationConverter: locationConverter,
                                                  disabledRegions: disabledRegions)
        let newTree = rewriter
            .visit(file.syntaxTree!)
        guard rewriter.sortedPositions.isNotEmpty else { return [] }

        file.write(newTree.description)
        return rewriter.sortedPositions.map { position in
            Correction(
                ruleDescription: Self.description,
                location: Location(file: file, byteOffset: ByteCount(position))
            )
        }
    }
}

// MARK: - ClosureSpacingRuleVisitor

private final class ClosureSpacingRuleVisitor: SyntaxVisitor {
    private var positions: [AbsolutePosition] = []
    var sortedPositions: [AbsolutePosition] { positions.sorted() }
    let locationConverter: SourceLocationConverter

    init(locationConverter: SourceLocationConverter) {
        self.locationConverter = locationConverter
    }

    override func visitPost(_ node: ClosureExprSyntax) {
        if node.shouldCheckForClosureSpacingRule(locationConverter: locationConverter),
           node.violations.hasViolations {
            positions.append(node.positionAfterSkippingLeadingTrivia)
        }
    }
}

// MARK: - ClosureSpacingRuleRewriter

private final class ClosureSpacingRuleRewriter: SyntaxRewriter {
    private var positions: [AbsolutePosition] = []
    var sortedPositions: [AbsolutePosition] { positions.sorted() }
    let locationConverter: SourceLocationConverter
    let disabledRegions: [SourceRange]

    init(locationConverter: SourceLocationConverter, disabledRegions: [SourceRange]) {
        self.locationConverter = locationConverter
        self.disabledRegions = disabledRegions
    }

    override func visit(_ node: ClosureExprSyntax) -> ExprSyntax {
        var node = node
        node.statements = visit(node.statements).as(CodeBlockItemListSyntax.self)!

        let isInDisabledRegion = disabledRegions.contains { region in
            region.contains(node.positionAfterSkippingLeadingTrivia, locationConverter: locationConverter)
        }
        if isInDisabledRegion {
            return ExprSyntax(node)
        }

        guard node.shouldCheckForClosureSpacingRule(locationConverter: locationConverter) else {
            return ExprSyntax(node)
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
            positions.append(node.positionAfterSkippingLeadingTrivia)
        }

        return ExprSyntax(node)
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
        if case let .spaces(spaces) = Array(leadingTrivia).last, spaces == 1 {
            return true
        }

        let combinedLeadingTriviaLength = leadingTriviaLength.utf8Length +
            (previousToken?.trailingTriviaLength.utf8Length ?? 0)
        return combinedLeadingTriviaLength == 1
    }

    var hasSingleSpaceToItsRight: Bool {
        if case let .spaces(spaces) = trailingTrivia.first, spaces == 1 {
            return true
        }

        let combinedTrailingTriviaLength = trailingTriviaLength.utf8Length +
            (nextToken?.leadingTriviaLength.utf8Length ?? 0)
        return combinedTrailingTriviaLength == 1
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
            .semicolon,
            .stringInterpolationAnchor
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

private extension Region {
    func toSourceRange(locationConverter: SourceLocationConverter) -> SourceRange? {
        guard let startLine = start.line, let endLine = end.line else {
            return nil
        }

        let startPosition = locationConverter.position(ofLine: startLine, column: min(1000, start.character ?? 1))
        let endPosition = locationConverter.position(ofLine: endLine, column: min(1000, end.character ?? 1))
        let startLocation = locationConverter.location(for: startPosition)
        let endLocation = locationConverter.location(for: endPosition)
        return SourceRange(start: startLocation, end: endLocation)
    }
}

private extension SourceRange {
    func contains(_ position: AbsolutePosition, locationConverter: SourceLocationConverter) -> Bool {
        contains(locationConverter.location(for: position))
    }

    func contains(_ location: SwiftSyntax.SourceLocation) -> Bool {
        start < location && location < end
    }
}

private extension SwiftSyntax.SourceLocation {
    static func < (lhs: Self, rhs: Self) -> Bool {
        if lhs.file != rhs.file {
            return lhs.file < rhs.file
        }
        if lhs.line != rhs.line {
            return lhs.line < rhs.line
        }
        return lhs.column < rhs.column
    }
}

private extension Optional where Wrapped: Comparable {
    static func < (lhs: Optional, rhs: Optional) -> Bool {
        switch (lhs, rhs) {
        case let (lhs?, rhs?):
            return lhs < rhs
        case (nil, _?):
            return true
        default:
            return false
        }
    }
}
