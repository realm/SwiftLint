/// Reports violations as JUnit XML supported by GitLab.
struct GitLabJUnitReporter: Reporter {
    // MARK: - Reporter Conformance

    static let identifier = "gitlab"
    static let isRealtime = false
    static let description = "Reports violations as JUnit XML supported by GitLab."

    static func generateReport(_ violations: [StyleViolation]) -> String {
        let warningCount = violations.filter({ $0.severity == .warning }).count
        let errorCount = violations.filter({ $0.severity == .error }).count
        let testCount = warningCount + errorCount

        return "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n" +
            "<testsuites failures=\"\(warningCount)\" errors=\"\(errorCount)\" tests=\"\(testCount)\">" +
            "<testsuite name=\"SwiftLint\" failures=\"\(warningCount)\" errors=\"\(errorCount)\" tests=\"\(testCount)\">" +
            violations.map({ violation -> String in
                let fileName = (violation.location.relativeFile ?? "<nopath>").escapedForXML()
                let line = violation.location.line.map(String.init)
                let column = violation.location.character.map(String.init)

                let severity = violation.severity.rawValue
                let rule = violation.ruleIdentifier
                let reason = violation.reason.escapedForXML()

                let location = [fileName, line].compactMap(\.self).joined(separator: ":")
                let message = "\(severity): \(rule) in \(location)"
                let body = """
                Severity: \(severity)
                Rule: \(rule)
                Reason: \(reason)

                File: \(fileName)
                Line: \(line ?? "nil")
                Column: \(column ?? "nil")
                """
                return [
                    "\n\t<testcase name='\(message)\'>\n",
                    "\t\t<failure>\(body)\n\t\t</failure>\n",
                    "\t</testcase>",
                ].joined()
            }).joined() + "\n</testsuite></testsuites>\n"
    }
}
