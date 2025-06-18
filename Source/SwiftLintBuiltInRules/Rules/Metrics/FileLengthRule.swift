import SwiftSyntax

@SwiftSyntaxRule
struct FileLengthRule: Rule {
    var configuration = FileLengthConfiguration()

    static let description = RuleDescription(
        identifier: "file_length",
        name: "File Length",
        description: "Files should not span too many lines.",
        kind: .metrics,
        nonTriggeringExamples: [
            Example(repeatElement("print(\"swiftlint\")\n", count: 399).joined())
        ],
        triggeringExamples: [
            Example(repeatElement("print(\"swiftlint\")\n", count: 401).joined()),
            Example((repeatElement("print(\"swiftlint\")\n", count: 400) + ["//\n"]).joined()),
            Example(repeatElement("print(\"swiftlint\")\n\n", count: 201).joined()),
        ].skipWrappingInCommentTests()
    )
}

private extension FileLengthRule {
    final class Visitor: ViolationsSyntaxVisitor<ConfigurationType> {
        override func visitPost(_ node: SourceFileSyntax) {
            let lineCount = configuration.ignoreCommentOnlyLines ? countNonCommentLines(in: node) : file.lines.count

            let severity: ViolationSeverity, upperBound: Int
            if let error = configuration.severityConfiguration.error, lineCount > error {
                severity = .error
                upperBound = error
            } else if lineCount > configuration.severityConfiguration.warning {
                severity = .warning
                upperBound = configuration.severityConfiguration.warning
            } else {
                return
            }

            let reason = "File should contain \(upperBound) lines or less" +
                       (configuration.ignoreCommentOnlyLines ? " excluding comments and whitespaces" : "") +
                       ": currently contains \(lineCount)"

            // Position violation at the start of the last line to avoid boundary issues
            let lastLine = file.lines.last
            let lastLineStartOffset = lastLine?.byteRange.location ?? 0
            let violationPosition = AbsolutePosition(utf8Offset: lastLineStartOffset.value)

            let violation = ReasonedRuleViolation(
                position: violationPosition,
                reason: reason,
                severity: severity
            )
            violations.append(violation)
        }

        private func countNonCommentLines(in node: SourceFileSyntax) -> Int {
            var linesWithActualContent = Set<Int>()

            for token in node.tokens(viewMode: .sourceAccurate) {
                addTokenContentLines(token, to: &linesWithActualContent)

                // Process leading trivia
                addTriviaLines(token.leadingTrivia, startingAt: token.position, to: &linesWithActualContent)
            }
            return linesWithActualContent.count
        }

        private func addTokenContentLines(_ token: TokenSyntax, to lines: inout Set<Int>) {
            // Skip tokens whose text is empty or only whitespace
            // (e.g., EOF token, or an unlikely malformed token).
            guard !token.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

            let startLocation = locationConverter.location(for: token.positionAfterSkippingLeadingTrivia)
            let endLocation = locationConverter.location(for: token.endPositionBeforeTrailingTrivia)

            addLinesInRange(from: startLocation.line, to: endLocation.line, to: &lines)
        }

        private func addTriviaLines(
            _ trivia: Trivia,
            startingAt startPosition: AbsolutePosition,
            to lines: inout Set<Int>
        ) {
            var currentPosition = startPosition
            for piece in trivia {
                if !piece.isComment && !piece.isWhitespace {
                    let startLocation = locationConverter.location(for: currentPosition)
                    let endLocation = locationConverter.location(for: currentPosition + piece.sourceLength)
                    addLinesInRange(from: startLocation.line, to: endLocation.line, to: &lines)
                }
                currentPosition += piece.sourceLength
            }
        }

        private func addLinesInRange(from startLine: Int, to endLine: Int, to lines: inout Set<Int>) {
            guard startLine > 0 && startLine <= endLine else { return }
            for line in startLine...endLine {
                lines.insert(line)
            }
        }
    }
}
