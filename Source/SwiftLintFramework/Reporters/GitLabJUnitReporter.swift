/// Reports violations as JUnit XML supported by GitLab.
public struct GitLabJUnitReporter: Reporter {
    // MARK: - Reporter Conformance

    public static let identifier = "gitlab"
    public static let isRealtime = false

    public var description: String {
        return "Reports violations as JUnit XML supported by GitLab."
    }

    public static func generateReport(_ violations: [StyleViolation]) -> String {
        return "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<testsuites><testsuite>" +
            violations.map({ violation -> String in
                let fileName = (violation.location.relativeFile ?? "<nopath>").escapedForXML()
                let line = violation.location.line.map(String.init)
                let column = violation.location.character.map(String.init)

                let severity = violation.severity.rawValue
                let rule = violation.ruleIdentifier
                let reason = violation.reason.escapedForXML()

                let location = [fileName, line].compactMap { $0 }.joined(separator: ":")
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
                    "\t</testcase>"
                ].joined()
            }).joined() + "\n</testsuite></testsuites>\n"
    }
}
