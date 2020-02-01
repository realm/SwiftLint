import Foundation

/// Reports violations as a newline-separated string of comma-separated values (CSV).
public struct CSVReporter: Reporter {
    // MARK: - Reporter Conformance

    public static let identifier = "csv"
    public static let isRealtime = false

    public var description: String {
        return "Reports violations as a newline-separated string of comma-separated values (CSV)."
    }

    public static func generateReport(_ violations: [StyleViolation]) -> String {
        let keys = [
            "file",
            "line",
            "character",
            "severity",
            "type",
            "reason",
            "rule_id"
        ].joined(separator: ",")

        let rows = [keys] + violations.map(csvRow(for:))
        return rows.joined(separator: "\n")
    }

    // MARK: - Private

    private static func csvRow(for violation: StyleViolation) -> String {
        return [
            violation.location.file?.escapedForCSV() ?? "",
            violation.location.line?.description ?? "",
            violation.location.character?.description ?? "",
            violation.severity.rawValue.capitalized,
            violation.ruleName.escapedForCSV(),
            violation.reason.escapedForCSV(),
            violation.ruleIdentifier
        ].joined(separator: ",")
    }
}

private extension String {
    func escapedForCSV() -> String {
        let escapedString = replacingOccurrences(of: "\"", with: "\"\"")
        if escapedString.contains(",") || escapedString.contains("\n") {
            return "\"\(escapedString)\""
        }
        return escapedString
    }
}
