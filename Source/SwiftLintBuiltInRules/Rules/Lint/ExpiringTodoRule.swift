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
            // Process the entire file to handle multiline comment cases
            let fileContent = file.contents

            do {
                let regex = try buildRegex()
                let matches = fileContent.matches(of: regex)

                for match in matches {
                    // Get the date capture group (first capture)
                    let fullMatchRange = match.range
                    let dateSubstring = match.output.1

                    // Find the range of the date capture within the full match
                    let fullMatch = String(fileContent[fullMatchRange])
                    guard let dateRangeInMatch = fullMatch.range(of: String(dateSubstring)) else { continue }

                    // Calculate the absolute position of the date capture
                    let dateStartIndex = fileContent.index(
                        fullMatchRange.lowerBound,
                        offsetBy: fullMatch.distance(from: fullMatch.startIndex, to: dateRangeInMatch.lowerBound)
                    )
                    let prefix = String(fileContent[..<dateStartIndex])
                    let matchOffset = prefix.utf8.count
                    let matchPosition = AbsolutePosition(utf8Offset: matchOffset)

                    guard isPositionInComment(position: matchPosition, in: node) else { continue }

                    let dateString = String(dateSubstring)
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
            } catch {
                // Invalid regex - should not happen
            }

            return .skipChildren
        }

        private func buildRegex() throws -> Regex<(Substring, Substring)> {
            let pattern = #"""
            \b(?:TODO|FIXME)(?::|\b)[\s\S]*?\#
            \\#(configuration.dateDelimiters.opening)\#
            (\d{1,4}\\#(configuration.dateSeparator)\d{1,4}\\#(configuration.dateSeparator)\d{1,4})\#
            \\#(configuration.dateDelimiters.closing)
            """#
            return try Regex(pattern, as: (Substring, Substring).self)
        }

        private func isPositionInComment(position: AbsolutePosition, in tree: SourceFileSyntax) -> Bool {
            // Walk through all tokens to find if the position is within a comment
            for token in tree.tokens(viewMode: .sourceAccurate) {
                // Check leading trivia
                var triviaOffset = token.position.utf8Offset
                for piece in token.leadingTrivia {
                    let pieceEndOffset = triviaOffset + piece.sourceLength.utf8Length
                    if position.utf8Offset >= triviaOffset && position.utf8Offset < pieceEndOffset {
                        return piece.isComment
                    }
                    triviaOffset = pieceEndOffset
                }

                // Check trailing trivia
                triviaOffset = token.endPositionBeforeTrailingTrivia.utf8Offset
                for piece in token.trailingTrivia {
                    let pieceEndOffset = triviaOffset + piece.sourceLength.utf8Length
                    if position.utf8Offset >= triviaOffset && position.utf8Offset < pieceEndOffset {
                        return piece.isComment
                    }
                    triviaOffset = pieceEndOffset
                }
            }

            return false
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
