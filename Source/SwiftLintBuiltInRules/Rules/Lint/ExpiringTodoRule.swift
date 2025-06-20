import Foundation
import SwiftSyntax

@SwiftSyntaxRule(optIn: true)
struct ExpiringTodoRule: Rule {
    enum ExpiryViolationLevel {
        case approachingExpiry
        case expired
        case badFormatting

        var reason: String {
            switch self {
            case .approachingExpiry:
                return "TODO/FIXME is approaching its expiry and should be resolved soon"
            case .expired:
                return "TODO/FIXME has expired and must be resolved"
            case .badFormatting:
                return "Expiring TODO/FIXME is incorrectly formatted"
            }
        }
    }

    static let description = RuleDescription(
        identifier: "expiring_todo",
        name: "Expiring Todo",
        description: "TODOs and FIXMEs should be resolved prior to their expiry date.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("// notaTODO:"),
            Example("// notaFIXME:"),
            Example("// TODO: [12/31/9999]"),
            Example("// TODO(note)"),
            Example("// FIXME(note)"),
            Example("/* FIXME: */"),
            Example("/* TODO: */"),
            Example("/** FIXME: */"),
            Example("/** TODO: */"),
        ],
        triggeringExamples: [
            Example("// TODO: [↓10/14/2019]"),
            Example("// FIXME: [↓10/14/2019]"),
            Example("// FIXME: [↓1/14/2019]"),
            Example("// FIXME: [↓10/14/2019]"),
            Example("// TODO: [↓9999/14/10]"),
        ].skipWrappingInCommentTests()
    )

    var configuration = ExpiringTodoConfiguration()
}

private extension ExpiringTodoRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
            let pattern = #"""
            \b(?:TODO|FIXME)(?::|\b)(?:(?!\b(?:TODO|FIXME)(?::|\b)).)*?\#
            \\#(configuration.dateDelimiters.opening)\#
            (\d{1,4}\\#(configuration.dateSeparator)\d{1,4}\\#(configuration.dateSeparator)\d{1,4})\#
            \\#(configuration.dateDelimiters.closing)
            """#

            let regex = SwiftLintCore.regex(pattern)

            // Process each comment individually
            for token in node.tokens(viewMode: .sourceAccurate) {
                processTrivia(
                    token.leadingTrivia,
                    baseOffset: token.position.utf8Offset,
                    regex: regex
                )
                processTrivia(
                    token.trailingTrivia,
                    baseOffset: token.endPositionBeforeTrailingTrivia.utf8Offset,
                    regex: regex
                )
            }

            return .skipChildren
        }

        private func processTrivia(_ trivia: Trivia, baseOffset: Int, regex: NSRegularExpression) {
            var triviaOffset = baseOffset

            for piece in trivia {
                defer { triviaOffset += piece.sourceLength.utf8Length }

                guard let commentText = piece.commentText else { continue }

                // Handle multiline comments by checking consecutive line comments
                if piece.isLineComment {
                    var combinedText = commentText
                    let currentOffset = triviaOffset

                    // Look ahead for consecutive line comments
                    let remainingTrivia = trivia.dropFirst(trivia.firstIndex(of: piece)! + 1)

                    for nextPiece in remainingTrivia {
                        if case .lineComment(let nextText) = nextPiece {
                            // Check if it's a continuation (starts with //)
                            if nextText.hasPrefix("//") {
                                combinedText += "\n" + nextText
                            } else {
                                break
                            }
                        } else if !nextPiece.isNewline && !nextPiece.isWhitespace {
                            break
                        }
                    }

                    processComment(combinedText, offset: currentOffset, regex: regex)
                } else {
                    processComment(commentText, offset: triviaOffset, regex: regex)
                }
            }
        }

        private func processComment(_ commentText: String, offset: Int, regex: NSRegularExpression) {
            let matches = regex.matches(in: commentText, options: [], range: commentText.fullNSRange)
            let nsStringComment = commentText.bridge()

            for match in matches {
                guard match.numberOfRanges > 1 else { continue }

                // Get the date capture group (second capture group, index 1)
                let dateRange = match.range(at: 1)
                guard dateRange.location != NSNotFound else { continue }

                let matchOffset = offset + dateRange.location
                let matchPosition = AbsolutePosition(utf8Offset: matchOffset)

                let dateString = nsStringComment.substring(with: dateRange)
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                if let violationLevel = getViolationLevel(for: parseDate(dateString: dateString)),
                   let severity = getSeverity(for: violationLevel) {
                    let violation = ReasonedRuleViolation(
                        position: matchPosition,
                        reason: violationLevel.reason,
                        severity: severity
                    )
                    violations.append(violation)
                }
            }
        }

        private func parseDate(dateString: String) -> Date? {
            let formatter = DateFormatter()
            formatter.calendar = .current
            formatter.dateFormat = configuration.dateFormat
            return formatter.date(from: dateString)
        }

        private func getSeverity(for violationLevel: ExpiryViolationLevel) -> ViolationSeverity? {
            switch violationLevel {
            case .approachingExpiry:
                return configuration.approachingExpirySeverity.severity
            case .expired:
                return configuration.expiredSeverity.severity
            case .badFormatting:
                return configuration.badFormattingSeverity.severity
            }
        }

        private func getViolationLevel(for expiryDate: Date?) -> ExpiryViolationLevel? {
            guard let expiryDate else {
                return .badFormatting
            }
            guard expiryDate.isAfterToday else {
                return .expired
            }
            guard let approachingDate = Calendar.current.date(
                byAdding: .day,
                value: -configuration.approachingExpiryThreshold,
                to: expiryDate) else {
                    return nil
            }
            return approachingDate.isAfterToday ?
                nil :
                .approachingExpiry
        }
    }
}

private extension Date {
    var isAfterToday: Bool {
        Calendar.current.compare(.init(), to: self, toGranularity: .day) == .orderedAscending
    }
}

private extension TriviaPiece {
    var isLineComment: Bool {
        switch self {
        case .lineComment, .docLineComment:
            return true
        default:
            return false
        }
    }

    var isWhitespace: Bool {
        switch self {
        case .spaces, .tabs:
            return true
        default:
            return false
        }
    }

    var isNewline: Bool {
        switch self {
        case .newlines, .carriageReturns, .carriageReturnLineFeeds:
            return true
        default:
            return false
        }
    }

    var commentText: String? {
        switch self {
        case .lineComment(let text), .blockComment(let text),
             .docLineComment(let text), .docBlockComment(let text):
            return text
        default:
            return nil
        }
    }
}
