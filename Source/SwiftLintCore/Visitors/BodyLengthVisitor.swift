import SwiftSyntax

/// A configuration that's based on warning and error thresholds for violations.
public protocol SeverityLevelsBasedRuleConfiguration<Parent>: RuleConfiguration {
    /// The severity configuration that defines the thresholds for warning and error severities.
    var severityConfiguration: SeverityLevelsConfiguration<Parent> { get }
}

extension SeverityLevelsConfiguration: SeverityLevelsBasedRuleConfiguration {
    public var severityConfiguration: SeverityLevelsConfiguration<Parent> { self }
}

/// Violation visitor customized to collect violations of code blocks that exceed a specified number of lines.
open class BodyLengthVisitor<LevelConfig: SeverityLevelsBasedRuleConfiguration>: ViolationsSyntaxVisitor<LevelConfig> {
    @inlinable
    override public init(configuration: LevelConfig, file: SwiftLintFile) {
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
        if let error = configuration.severityConfiguration.error, lineCount > error {
            severity = .error
            upperBound = error
        } else if lineCount > configuration.severityConfiguration.warning {
            severity = .warning
            upperBound = configuration.severityConfiguration.warning
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
