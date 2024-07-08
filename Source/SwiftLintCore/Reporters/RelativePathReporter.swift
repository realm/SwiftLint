/// Reports violations with relative paths.
struct RelativePathReporter: Reporter {
    // MARK: - Reporter Conformance

    static let identifier = "relative-path"
    static let isRealtime = true
    static let description = "Reports violations with relative paths."

    static func generateReport(_ violations: [StyleViolation]) -> String {
        violations.map(generateForSingleViolation).joined(separator: "\n")
    }

    /// Generates a report for a single violation.
    ///
    /// - parameter violation: The violation to report.
    ///
    /// - returns: The report for a single violation.
    internal static func generateForSingleViolation(_ violation: StyleViolation) -> String {
        // {relative_path_to_file}{:line}{:character}: {error,warning}: {content}

        [
            "\(violation.location.relativeFile ?? "<nopath>")",
            ":\(violation.location.line ?? 1)",
            ":\(violation.location.character ?? 1): ",
            "\(violation.severity.rawValue): ",
            "\(violation.ruleName) Violation: ",
            violation.reason,
            " (\(violation.ruleIdentifier))",
        ].joined()
    }
}
