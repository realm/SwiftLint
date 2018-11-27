import Foundation

private extension String {
    func escapedForMarkdown() -> String {
        let escapedString = replacingOccurrences(of: "\"", with: "\"\"")
        if escapedString.contains("|") || escapedString.contains("\n") {
            return "\"\(escapedString)\""
        }
        return escapedString
    }
}

public struct MarkdownReporter: Reporter {
    public static let identifier = "markdown"
    public static let isRealtime = false

    public var description: String {
        return "Reports violations as markdown formated (with tables)"
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

    fileprivate static func markdownRow(for violation: StyleViolation) -> String {
        return [
            violation.location.file?.escapedForMarkdown() ?? "",
            violation.location.line?.description ?? "",
            severity(for: violation.severity),
            violation.ruleDescription.name.escapedForMarkdown() + ": " + violation.reason.escapedForMarkdown(),
            violation.ruleDescription.identifier
        ].joined(separator: " | ")
    }

    fileprivate static func severity(for severity: ViolationSeverity) -> String {
        switch severity {
        case .error:
            return ":stop\\_sign:"
        case .warning:
            return ":warning:"
        }
    }
}
