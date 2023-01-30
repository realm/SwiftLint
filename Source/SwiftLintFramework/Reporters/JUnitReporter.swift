/// Reports violations as JUnit XML.
public struct JUnitReporter: Reporter {
    // MARK: - Reporter Conformance

    public static let identifier = "junit"
    public static let isRealtime = false

    public var description: String {
        return "Reports violations as JUnit XML."
    }

    public static func generateReport(_ violations: [StyleViolation]) -> String {
        let warningCount = violations.filter({ $0.severity == .warning }).count
        let errorCount = violations.filter({ $0.severity == .error }).count

        return [
            "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n",
            "<testsuites failures=\"\(warningCount)\" errors=\"\(errorCount)\">\n",
            "\t<testsuite failures=\"\(warningCount)\" errors=\"\(errorCount)\">",
            violations.map({ testCase(for: $0) }).joined(),
            "\n\t</testsuite>\n",
            "</testsuites>"
        ].joined()
    }

    private static func testCase(for violation: StyleViolation) -> String {
        let fileName = (violation.location.file ?? "<nopath>").escapedForXML()
        let reason = violation.reason.escapedForXML()
        let severity = violation.severity.rawValue.capitalized
        let lineNumber = String(violation.location.line ?? 0)
        let message = severity + ":" + "Line:" + lineNumber

        return [
            "\n\t\t<testcase classname='Formatting Test' name='\(fileName)\'>",
            "\n\t\t\t<failure message='\(reason)\'>" + message + "</failure>",
            "\n\t\t</testcase>"
        ].joined()
    }
}
