/// An interface for reporting violations as strings.
public protocol Reporter: CustomStringConvertible {
    /// The unique identifier for this reporter.
    static var identifier: String { get }

    /// Whether or not this reporter can output incrementally as violations are found or if all violations must be
    /// collected before generating the report.
    static var isRealtime: Bool { get }

    /// A more detailed description of the reporter's output.
    static var description: String { get }

    /// For CustomStringConvertible conformance.
    var description: String { get }

    /// Return a string with the report for the specified violations.
    ///
    /// - parameter violations: The violations to report.
    ///
    /// - returns: The report.
    static func generateReport(_ violations: [StyleViolation]) -> String
}

extension Reporter {
    /// For CustomStringConvertible conformance.
    var description: String { Self.description }
}

/// Returns the reporter with the specified identifier. Traps if the specified identifier doesn't correspond to any
/// known reporters.
///
/// - parameter identifier: The identifier corresponding to the reporter.
///
/// - returns: The reporter type.
public func reporterFrom(identifier: String?) -> any Reporter.Type {
    guard let identifier else {
        return XcodeReporter.self
    }
    guard let reporter = reportersList.first(where: { $0.identifier == identifier }) else {
        queuedFatalError("No reporter with identifier '\(identifier)' available.")
    }
    return reporter
}
