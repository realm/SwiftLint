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
            let lineCount = configuration.ignoreCommentOnlyLines
                ? CommentLinesVisitor(locationConverter: locationConverter)
                    .walk(tree: node, handler: \.linesWithCode).count
                : file.lines.count

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
    }
}
