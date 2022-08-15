import SourceKittenFramework
import SwiftSyntax

public struct ClosureSpacingRule: ConfigurationProviderRule, OptInRule, SourceKitFreeRule {
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
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        guard let locationConverter = file.locationConverter else {
            return []
        }

        return MultilineClosureRuleVisitor(locationConverter: locationConverter)
            .walk(file: file, handler: \.sortedPositions)
            .map { position in
                StyleViolation(ruleDescription: Self.description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: ByteCount(position)))
            }
    }
}

private final class MultilineClosureRuleVisitor: SyntaxVisitor {
    private var positions: [AbsolutePosition] = []
    var sortedPositions: [AbsolutePosition] { positions.sorted() }
    let locationConverter: SourceLocationConverter

    init(locationConverter: SourceLocationConverter) {
        self.locationConverter = locationConverter
    }

    override func visitPost(_ node: ClosureExprSyntax) {
        guard node.parent?.is(PostfixUnaryExprSyntax.self) == false else {
            // Workaround for Regex literals
            return
        }

        guard let startLine = node.startLocation(converter: self.locationConverter).line,
              let endLine = node.endLocation(converter: self.locationConverter).line,
              startLine == endLine, // Only check single-line closures
              (node.rightBrace.position.utf8Offset - node.leftBrace.position.utf8Offset) > 1 // That aren't '{}'
        else {
            return
        }

        let violationPosition = node.positionAfterSkippingLeadingTrivia
        if !node.leftBrace.hasSingleSpaceToItsLeft && !node.leftBrace.previousTokenIsAllowed &&
            !node.leftBrace.hasLeadingNewline {
            positions.append(violationPosition)
        } else if !node.leftBrace.hasSingleSpaceToItsRight {
            positions.append(violationPosition)
        } else if !node.rightBrace.hasSingleSpaceToItsLeft {
            positions.append(violationPosition)
        } else if !node.rightBrace.hasSingleSpaceToItsRight && !node.rightBrace.nextTokenIsRightParenOrEOF &&
                    !node.rightBrace.hasAllowedNoSpaceToken && !node.rightBrace.hasTrailingLineComment {
            positions.append(violationPosition)
        }
    }
}

private extension TokenSyntax {
    var previousTokenIsAllowed: Bool {
        parent?.previousToken?.tokenKind == .leftParen || parent?.previousToken?.tokenKind == .leftSquareBracket
    }

    var nextTokenIsRightParenOrEOF: Bool {
        (parent?.nextToken?.tokenKind == .rightParen) ||
            (parent?.nextToken?.tokenKind == .eof)
    }

    var hasSingleSpaceToItsLeft: Bool {
        leadingTriviaLength.utf8Length +
            (previousToken?.trailingTriviaLength.utf8Length ?? 0) == 1
    }

    var hasSingleSpaceToItsRight: Bool {
        if case let .spaces(spaces) = trailingTrivia.first, spaces == 1 {
            return true
        }

        return trailingTriviaLength.utf8Length +
            (nextToken?.leadingTriviaLength.utf8Length ?? 0) == 1
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

    var hasAllowedNoSpaceToken: Bool {
        let allowedKinds = [
            TokenKind.colon,
            .comma,
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
