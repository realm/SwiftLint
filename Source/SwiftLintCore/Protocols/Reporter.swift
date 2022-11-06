/// An interface for reporting violations as strings.
public protocol Reporter: CustomStringConvertible {
    /// The unique identifier for this reporter.
    static var identifier: String { get }

    /// Whether or not this reporter can output incrementally as violations are found or if all violations must be
    /// collected before generating the report.
    static var isRealtime: Bool { get }

    /// Return a string with the report for the specified violations.
    ///
    /// - parameter violations: The violations to report.
    ///
    /// - returns: The report.
    static func generateReport(_ violations: [StyleViolation]) -> String
}

/// Returns the reporter with the specified identifier. Traps if the specified identifier doesn't correspond to any
/// known reporters.
///
/// - parameter identifier: The identifier corresponding to the reporter.
///
/// - returns: The reporter type.
public func reporterFrom(identifier: String) -> Reporter.Type { // swiftlint:disable:this cyclomatic_complexity
    switch identifier {
    case XcodeReporter.identifier:
        return XcodeReporter.self
    case JSONReporter.identifier:
        return JSONReporter.self
    case CSVReporter.identifier:
        return CSVReporter.self
    case CheckstyleReporter.identifier:
        return CheckstyleReporter.self
    case JUnitReporter.identifier:
        return JUnitReporter.self
    case HTMLReporter.identifier:
        return HTMLReporter.self
    case EmojiReporter.identifier:
        return EmojiReporter.self
    case SonarQubeReporter.identifier:
        return SonarQubeReporter.self
    case MarkdownReporter.identifier:
        return MarkdownReporter.self
    case GitHubActionsLoggingReporter.identifier:
        return GitHubActionsLoggingReporter.self
    case GitLabJUnitReporter.identifier:
        return GitLabJUnitReporter.self
    case CodeClimateReporter.identifier:
        return CodeClimateReporter.self
    default:
        queuedFatalError("no reporter with identifier '\(identifier)' available.")
    }
}
