import Foundation
import SwiftSyntax

struct TodoRule: SwiftSyntaxRule, ConfigurationProviderRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "todo",
        name: "Todo",
        description: "TODOs and FIXMEs should be resolved.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("// notaTODO:\n"),
            Example("// notaFIXME:\n")
        ],
        triggeringExamples: [
            Example("// ↓TODO:\n"),
            Example("// ↓FIXME:\n"),
            Example("// ↓TODO(note)\n"),
            Example("// ↓FIXME(note)\n"),
            Example("/* ↓FIXME: */\n"),
            Example("/* ↓TODO: */\n"),
            Example("/** ↓FIXME: */\n"),
            Example("/** ↓TODO: */\n")
        ].skipWrappingInCommentTests()
    )

    func makeVisitor(file: SwiftLintFile) -> ViolationsSyntaxVisitor {
        Visitor(viewMode: .sourceAccurate)
    }
}

private extension TodoRule {
    final class Visitor: ViolationsSyntaxVisitor {
        override func visitPost(_ node: TokenSyntax) {
            let leadingViolations = node.leadingTrivia.violations(offset: node.position)
            let trailingViolations = node.trailingTrivia.violations(offset: node.endPositionBeforeTrailingTrivia)
            violations.append(contentsOf: leadingViolations + trailingViolations)
        }
    }
}

private extension Trivia {
    func violations(offset: AbsolutePosition) -> [ReasonedRuleViolation] {
        var position = offset
        var violations = [ReasonedRuleViolation]()
        for piece in self {
            violations.append(contentsOf: piece.violations(offset: position))
            position += piece.sourceLength
        }
        return violations
    }
}

private extension TriviaPiece {
    func violations(offset: AbsolutePosition) -> [ReasonedRuleViolation] {
        switch self {
        case
                .blockComment(let comment),
                .lineComment(let comment),
                .docBlockComment(let comment),
                .docLineComment(let comment):
            let matches = regex(#"\b((?:TODO|FIXME)(?::|\b))"#)
                .matches(in: comment, range: comment.bridge().fullNSRange)
            return matches.reduce(into: []) { violations, match in
                guard let annotationRange = Range(match.range(at: 1), in: comment) else {
                    return
                }

                let maxLengthOfMessage = 30

                // customizing the reason message to be specific to fixme or todo
                let kind = comment[annotationRange].hasPrefix("FIXME") ? "FIXMEs" : "TODOs"
                let message = comment[annotationRange.upperBound...]
                    .trimmingCharacters(in: .whitespaces)
                    .truncated(maxLength: maxLengthOfMessage)
                    .prefix { $0 != "\n" }

                let reason: String
                if message.isEmpty {
                    reason = "\(kind) should be resolved"
                } else {
                    reason = "\(kind) should be resolved (\(message))"
                }

                let violation = ReasonedRuleViolation(
                    position: offset.advanced(by: comment[..<annotationRange.lowerBound].utf8.count),
                    reason: reason
                )
                violations.append(violation)
            }
        default:
            return []
        }
    }
}

private extension String {
    func truncated(maxLength: Int) -> String {
        if utf16.count > maxLength {
            let end = index(startIndex, offsetBy: maxLength, limitedBy: endIndex) ?? endIndex
            return self[..<end] + "..."
        } else {
            return self
        }
    }
}
