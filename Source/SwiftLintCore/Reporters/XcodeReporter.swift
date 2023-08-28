/// Reports violations in the format Xcode uses to display in the IDE. (default)
struct XcodeReporter: Reporter {
    // MARK: - Reporter Conformance

    static let identifier = "xcode"
    static let isRealtime = true
    static let description = "Reports violations in the format Xcode uses to display in the IDE. (default)"

    static func generateReport(_ violations: [StyleViolation]) -> String {
        return violations.map(generateForSingleViolation).joined(separator: "\n")
    }

    /// Generates a report for a single violation.
    ///
    /// - parameter violation: The violation to report.
    ///
    /// - returns: The report for a single violation.
    internal static func generateForSingleViolation(_ violation: StyleViolation) -> String {
        // {full_path_to_file}{:line}{:character}: {error,warning}: {content}
        return [
            "\(violation.location): ",
            "\(violation.severity.rawValue): ",
            "\(violation.ruleName) Violation: ",
            violation.reason,
            " (\(violation.ruleIdentifier))"
        ].joined()
    }
}
