/// Reports violations in the format Xcode uses to display in the IDE. (default)
struct XcodeReporter: Reporter {
    // MARK: - Reporter Conformance

    static let identifier = "xcode"
    static let isRealtime = true
    static let description = "Reports violations in the format Xcode uses to display in the IDE. (default)"

    static func generateReport(_ violations: [StyleViolation]) -> String {
        violations.map(generateForSingleViolation).joined(separator: "\n")
    }

    /// Generates a report for a single violation.
    ///
    /// - parameter violation: The violation to report.
    ///
    /// - returns: The report for a single violation.
    internal static func generateForSingleViolation(_ violation: StyleViolation) -> String {
        violation.description
    }
}
