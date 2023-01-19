/// Reports violations in a format that's both fun and easy to read.
public struct EmojiReporter: Reporter {
    // MARK: - Reporter Conformance

    public static let identifier = "emoji"
    public static let isRealtime = false

    public var description: String {
        return "Reports violations in the format that's both fun and easy to read."
    }

    public static func generateReport(_ violations: [StyleViolation]) -> String {
        violations
            .group { $0.location.file ?? "Other" }
            .sorted { $0.key < $1.key }
            .map(report)
            .joined(separator: "\n")
    }

    // MARK: - Private

    private static func report(for file: String, with violations: [StyleViolation]) -> String {
        let issueList = violations
            .sorted { $0.severity == $1.severity ? $0.location > $1.location : $0.severity > $1.severity }
            .map { violation in
                let emoji = violation.severity == .error ? "⛔️" : "⚠️"
                var lineString = ""
                if let line = violation.location.line {
                    lineString = "Line \(line): "
                }
                return "\(emoji) \(lineString)\(violation.reason) (\(violation.ruleIdentifier))"
            }
            .joined(separator: "\n")
        return """
            \(file)
            \(issueList)
            """
    }
}
