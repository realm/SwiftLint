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
                "TODO/FIXME is approaching its expiry and should be resolved soon"
            case .expired:
                "TODO/FIXME has expired and must be resolved"
            case .badFormatting:
                "Expiring TODO/FIXME is incorrectly formatted"
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
        private lazy var regex: NSRegularExpression = {
            let pattern = #"""
            \b(?:TODO|FIXME)(?::|\b)(?:(?!\b(?:TODO|FIXME)(?::|\b)).)*?\#
            \\#(configuration.dateDelimiters.opening)\#
            (\d{1,4}\\#(configuration.dateSeparator)\d{1,4}\\#(configuration.dateSeparator)\d{1,4})\#
            \\#(configuration.dateDelimiters.closing)
            """#
            return SwiftLintCore.regex(pattern)
        }()

        override func visit(_ node: SourceFileSyntax) -> SyntaxVisitorContinueKind {
            // Process each comment individually
            for token in node.tokens(viewMode: .sourceAccurate) {
                processTrivia(
                    token.leadingTrivia,
                    baseOffset: token.position.utf8Offset
                )
                processTrivia(
                    token.trailingTrivia,
                    baseOffset: token.endPositionBeforeTrailingTrivia.utf8Offset
                )
            }

            return .skipChildren
        }

        private func processTrivia(_ trivia: Trivia, baseOffset: Int) {
            var triviaOffset = baseOffset

            for (index, piece) in trivia.enumerated() {
                defer { triviaOffset += piece.sourceLength.utf8Length }

                guard let commentText = piece.commentText else { continue }

                // Handle multiline comments by checking consecutive line comments
                if piece.isLineComment {
                    var combinedText = commentText
                    let currentOffset = triviaOffset

                    // Look ahead for consecutive line comments
                    let remainingTrivia = trivia.dropFirst(index + 1)

                    for nextPiece in remainingTrivia {
                        if case .lineComment(let nextText) = nextPiece {
                            // Check if it's a continuation (starts with //)
                            if nextText.hasPrefix("//") {
                                combinedText += "\n" + nextText
                            } else {
                                break
                            }
                        } else if !nextPiece.isWhitespace {
                            break
                        }
                    }

                    processComment(combinedText, offset: currentOffset)
                } else {
                    processComment(commentText, offset: triviaOffset)
                }
            }
        }

        private func processComment(_ commentText: String, offset: Int) {
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
                configuration.approachingExpirySeverity.severity
            case .expired:
                configuration.expiredSeverity.severity
            case .badFormatting:
                configuration.badFormattingSeverity.severity
            }
        }

        private func getViolationLevel(for expiryDate: Date?) -> ExpiryViolationLevel? {
            guard let expiryDate else {
                return .badFormatting
            }

            guard expiryDate.isAfterToday else {
                return .expired
            }

            let approachingDate = Calendar.current.date(
                byAdding: .day,
                value: -configuration.approachingExpiryThreshold,
                to: expiryDate
            )

            guard let approachingDate else {
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
            true
        default:
            false
        }
    }

    var commentText: String? {
        switch self {
        case .lineComment(let text), .blockComment(let text),
             .docLineComment(let text), .docBlockComment(let text):
            text
        default:
            nil
        }
    }
}
