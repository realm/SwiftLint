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

        return """
            <?xml version="1.0" encoding="utf-8"?>
            <testsuites failures="\(warningCount)" errors="\(errorCount)">
            \t<testsuite failures="\(warningCount)" errors="\(errorCount)">
            \(violations.map(testCase(for:)).joined(separator: "\n"))
            \t</testsuite>
            </testsuites>
            """
    }

    private static func testCase(for violation: StyleViolation) -> String {
        let fileName = (violation.location.file ?? "<nopath>").escapedForXML()
        let reason = violation.reason.escapedForXML()
        let severity = violation.severity.rawValue.capitalized
        let lineNumber = String(violation.location.line ?? 0)
        let message = severity + ":" + "Line:" + lineNumber

        return """
            \t\t<testcase classname='Formatting Test' name='\(fileName)'>
            \t\t\t<failure message='\(reason)'>\(message)</failure>
            \t\t</testcase>
            """
    }
}
