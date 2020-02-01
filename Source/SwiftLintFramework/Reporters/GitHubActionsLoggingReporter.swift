/// Reports violations in the format GitHub-hosted virtual machine for Actions can recognize as messages.
public struct GitHubActionsLoggingReporter: Reporter {
    // MARK: - Reporter Conformance

    public static let identifier = "github-actions-logging"
    public static let isRealtime = true

    public var description: String {
        return "Reports violations in the format GitHub-hosted virtual machine for Actions can recognize as messages."
    }

    public static func generateReport(_ violations: [StyleViolation]) -> String {
        return violations.map(generateForSingleViolation).joined(separator: "\n")
    }

    // MARK: - Private

    private static func generateForSingleViolation(_ violation: StyleViolation) -> String {
        // swiftlint:disable:next line_length
        // https://help.github.com/en/github/automating-your-workflow-with-github-actions/development-tools-for-github-actions#logging-commands
        // ::(warning|error) file={relative_path_to_file},line={:line},col={:character}::{content}
        return [
            "::\(violation.severity.rawValue) ",
            "file=\(violation.location.relativeFile ?? ""),",
            "line=\(violation.location.line ?? 1),",
            "col=\(violation.location.character ?? 1)::",
            violation.reason,
            " (\(violation.ruleIdentifier))"
        ].joined()
    }
}
