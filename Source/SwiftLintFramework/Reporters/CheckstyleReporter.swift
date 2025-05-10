/// Reports violations as XML conforming to the Checkstyle specification, as defined here:
/// https://www.jetbrains.com/help/teamcity/xml-report-processing.html
struct CheckstyleReporter: Reporter {
    // MARK: - Reporter Conformance

    static let identifier = "checkstyle"
    static let isRealtime = false
    static let description = "Reports violations as Checkstyle XML."

    static func generateReport(_ violations: [StyleViolation]) -> String {
        [
            "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<checkstyle version=\"4.3\">",
            violations
                .group(by: { ($0.location.file ?? "<nopath>").escapedForXML() })
                .sorted(by: { $0.key < $1.key })
                .map(generateForViolationFile).joined(),
            "\n</checkstyle>",
        ].joined()
    }

    // MARK: - Private

    private static func generateForViolationFile(_ file: String, violations: [StyleViolation]) -> String {
        [
            "\n\t<file name=\"", file, "\">\n",
            violations.map(generateForSingleViolation).joined(),
            "\t</file>",
        ].joined()
    }

    private static func generateForSingleViolation(_ violation: StyleViolation) -> String {
        let line: Int = violation.location.line ?? 0
        let col: Int = violation.location.character ?? 0
        let severity: String = violation.severity.rawValue
        let reason: String = violation.reason.escapedForXML()
        let identifier: String = violation.ruleIdentifier
        let source: String = "swiftlint.rules.\(identifier)".escapedForXML()
        return [
            "\t\t<error line=\"\(line)\" ",
            "column=\"\(col)\" ",
            "severity=\"", severity, "\" ",
            "message=\"", reason, "\" ",
            "source=\"\(source)\"/>\n",
        ].joined()
    }
}
