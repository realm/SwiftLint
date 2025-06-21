import SwiftSyntax

/// Violation visitor customized to collect violations of code blocks that exceed a specified number of lines.
open class BodyLengthVisitor<Parent: Rule>: ViolationsSyntaxVisitor<SeverityLevelsConfiguration<Parent>> {
    @inlinable
    override public init(configuration: SeverityLevelsConfiguration<Parent>, file: SwiftLintFile) {
        super.init(configuration: configuration, file: file)
    }

    /// Registers a violation if a body exceeds the configured line count.
    ///
    /// - Parameters:
    ///   - leftBrace: The left brace token of the body.
    ///   - rightBrace: The right brace token of the body.
    ///   - violationNode: The syntax node where the violation is to be reported.
    ///   - objectName: The name of the object (e.g., "Function", "Closure") used in the violation message.
    public func registerViolations(leftBrace: TokenSyntax,
                                   rightBrace: TokenSyntax,
                                   violationNode: some SyntaxProtocol,
                                   objectName: String) {
        let leftBracePosition = leftBrace.positionAfterSkippingLeadingTrivia
        let leftBraceLine = locationConverter.location(for: leftBracePosition).line
        let rightBracePosition = rightBrace.positionAfterSkippingLeadingTrivia
        let rightBraceLine = locationConverter.location(for: rightBracePosition).line
        let lineCount = file.bodyLineCountIgnoringCommentsAndWhitespace(leftBraceLine: leftBraceLine,
                                                                        rightBraceLine: rightBraceLine)
        let severity: ViolationSeverity, upperBound: Int
        if let error = configuration.error, lineCount > error {
            severity = .error
            upperBound = error
        } else if lineCount > configuration.warning {
            severity = .warning
            upperBound = configuration.warning
        } else {
            return
        }

        violations.append(.init(
            position: violationNode.positionAfterSkippingLeadingTrivia,
            reason: """
                \(objectName) body should span \(upperBound) lines or less excluding comments and whitespace: \
                currently spans \(lineCount) lines
                """,
            severity: severity
        ))
    }
}
