/// Reports violations in the format that's both fun and easy to read.
public struct EmojiReporter: Reporter {
    // MARK: - Reporter Conformance

    public static let identifier = "emoji"
    public static let isRealtime = false

    public var description: String {
        return "Reports violations in the format that's both fun and easy to read."
    }

    public static func generateReport(_ violations: [StyleViolation]) -> String {
        return violations
            .group { $0.location.file ?? "Other" }
            .sorted { $0.key < $1.key }
            .map(report)
            .joined(separator: "\n")
    }

    // MARK: - Private

    private static func report(for file: String, with violations: [StyleViolation]) -> String {
        let lines = [file] + violations.sorted { lhs, rhs in
            guard lhs.severity == rhs.severity else {
                return lhs.severity > rhs.severity
            }
            return lhs.location > rhs.location
        }.map { violation in
            let emoji = (violation.severity == .error) ? "⛔️" : "⚠️"
            let lineString: String
            if let line = violation.location.line {
                lineString = "Line \(line): "
            } else {
                lineString = ""
            }
            return "\(emoji) \(lineString)\(violation.reason)"
        }
        return lines.joined(separator: "\n")
    }
}
