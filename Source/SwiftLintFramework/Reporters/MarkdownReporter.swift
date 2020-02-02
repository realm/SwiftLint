import Foundation

/// Reports violations as markdown formated (with tables).
public struct MarkdownReporter: Reporter {
    // MARK: - Reporter Conformance

    public static let identifier = "markdown"
    public static let isRealtime = false

    public var description: String {
        return "Reports violations as markdown formated (with tables)."
    }

    public static func generateReport(_ violations: [StyleViolation]) -> String {
        let keys = [
            "file",
            "line",
            "severity",
            "reason",
            "rule_id"
        ].joined(separator: " | ")

        let rows = [keys, "--- | --- | --- | --- | ---"] + violations.map(markdownRow(for:))
        return rows.joined(separator: "\n")
    }

    // MARK: - Private

    private static func markdownRow(for violation: StyleViolation) -> String {
        return [
            violation.location.file?.escapedForMarkdown() ?? "",
            violation.location.line?.description ?? "",
            severity(for: violation.severity),
            violation.ruleName.escapedForMarkdown() + ": " + violation.reason.escapedForMarkdown(),
            violation.ruleIdentifier
        ].joined(separator: " | ")
    }

    private static func severity(for severity: ViolationSeverity) -> String {
        switch severity {
        case .error:
            return ":stop\\_sign:"
        case .warning:
            return ":warning:"
        }
    }
}

private extension String {
    func escapedForMarkdown() -> String {
        let escapedString = replacingOccurrences(of: "\"", with: "\"\"")
        if escapedString.contains("|") || escapedString.contains("\n") {
            return "\"\(escapedString)\""
        }
        return escapedString
    }
}
