import Foundation

private let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    return formatter
}()

/// Reports violations as HTML.
public struct HTMLReporter: Reporter {
    // MARK: - Reporter Conformance

    public static let identifier = "html"
    public static let isRealtime = false

    public var description: String {
        return "Reports violations as HTML."
    }

    public static func generateReport(_ violations: [StyleViolation]) -> String {
        return generateReport(violations, swiftlintVersion: Version.current.value,
                              dateString: formatter.string(from: Date()))
    }

    // MARK: - Internal

    // swiftlint:disable:next function_body_length
    internal static func generateReport(_ violations: [StyleViolation], swiftlintVersion: String,
                                        dateString: String) -> String {
        let rows = violations.enumerated().reduce(into: "") { rows, indexAndViolation in
            rows.append(generateSingleRow(for: indexAndViolation.1, at: indexAndViolation.0 + 1))
        }

        let fileCount = Set(violations.compactMap({ $0.location.file })).count
        let warningCount = violations.filter({ $0.severity == .warning }).count
        let errorCount = violations.filter({ $0.severity == .error }).count

        return [
            "<!doctype html>\n",
            "<html>\n",
            "\t<head>\n",
            "\t\t<meta charset=\"utf-8\" />\n",
            "\t\t<meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\" />\n",
            "\t\t\n",
            "\t\t<style type=\"text/css\">\n",
            "\t\t\tbody {\n",
            "\t\t\t\tfont-family: Arial, Helvetica, sans-serif;\n",
            "\t\t\t\tfont-size: 0.9rem;\n",
            "\t\t\t}\n",
            "\t\t\t\n",
            "\t\t\ttable {\n",
            "\t\t\t\tborder: 1px solid gray;\n",
            "\t\t\t\tborder-collapse: collapse;\n",
            "\t\t\t\t-moz-box-shadow: 3px 3px 4px #AAA;\n",
            "\t\t\t\t-webkit-box-shadow: 3px 3px 4px #AAA;\n",
            "\t\t\t\tbox-shadow: 3px 3px 4px #AAA;\n",
            "\t\t\t\tvertical-align: top;\n",
            "\t\t\t\theight: 64px;\n",
            "\t\t\t}\n",
            "\t\t\t\n",
            "\t\t\ttd, th {\n",
            "\t\t\t\tborder: 1px solid #D3D3D3;\n",
            "\t\t\t\tpadding: 5px 10px 5px 10px;\n",
            "\t\t\t}\n",
            "\t\t\t\n",
            "\t\t\tth {\n",
            "\t\t\t\tborder-bottom: 1px solid gray;\n",
            "\t\t\t\tbackground-color: rgba(41,52,92,0.313);\n",
            "\t\t\t}\n",
            "\t\t\t\n",
            "\t\t\t.error, .warning {\n",
            "\t\t\t\ttext-align: center;\n",
            "\t\t\t}\n",
            "\t\t\t\n",
            "\t\t\t.error {\n",
            "\t\t\t\tbackground-color: #FF9D92;\n",
            "\t\t\t\tcolor: #7F0800;\n",
            "\t\t\t}\n",
            "\t\t\t\n",
            "\t\t\t.warning {\n",
            "\t\t\t\tbackground-color: #FFF59E;\n",
            "\t\t\t\tcolor: #7F7000;\n",
            "\t\t\t}\n",
            "\t\t</style>\n",
            "\t\t\n",
            "\t\t<title>SwiftLint Report</title>\n",
            "\t</head>\n",
            "\t<body>\n",
            "\t\t<h1>SwiftLint Report</h1>\n",
            "\t\t\n",
            "\t\t<hr />\n",
            "\t\t\n",
            "\t\t<h2>Violations</h2>\n",
            "\t\t\n",
            "\t\t<table>\n",
            "\t\t\t<thead>\n",
            "\t\t\t\t<tr>\n",
            "\t\t\t\t\t<th style=\"width: 60pt;\">\n",
            "\t\t\t\t\t\t<b>Serial No.</b>\n",
            "\t\t\t\t\t</th>\n",
            "\t\t\t\t\t<th style=\"width: 500pt;\">\n",
            "\t\t\t\t\t\t<b>File</b>\n",
            "\t\t\t\t\t</th>\n",
            "\t\t\t\t\t<th style=\"width: 60pt;\">\n",
            "\t\t\t\t\t\t<b>Location</b>\n",
            "\t\t\t\t\t</th>\n",
            "\t\t\t\t\t<th style=\"width: 60pt;\">\n",
            "\t\t\t\t\t\t<b>Severity</b>\n",
            "\t\t\t\t\t</th>\n",
            "\t\t\t\t\t<th style=\"width: 500pt;\">\n",
            "\t\t\t\t\t\t<b>Message</b>\n",
            "\t\t\t\t\t</th>\n",
            "\t\t\t\t</tr>\n",
            "\t\t\t</thead>\n",
            "\t\t\t<tbody>\n", rows, "\t\t\t</tbody>\n",
            "\t\t</table>\n",
            "\t\t\n",
            "\t\t<br/>\n",
            "\t\t\n",
            "\t\t<h2>Summary</h2>\n",
            "\t\t\n",
            "\t\t<table>\n",
            "\t\t\t<tbody>\n",
            "\t\t\t\t<tr>\n",
            "\t\t\t\t\t<td>Total files with violations</td>\n",
            "\t\t\t\t\t<td>\(fileCount)</td>\n",
            "\t\t\t\t</tr>\n",
            "\t\t\t\t<tr>\n",
            "\t\t\t\t\t<td>Total warnings</td>\n",
            "\t\t\t\t\t<td>\(warningCount)</td>\n",
            "\t\t\t\t</tr>\n",
            "\t\t\t\t<tr>\n",
            "\t\t\t\t\t<td>Total errors</td>\n",
            "\t\t\t\t\t<td>\(errorCount)</td>\n",
            "\t\t\t\t</tr>\n",
            "\t\t\t</tbody>\n",
            "\t\t</table>\n",
            "\t\t\n",
            "\t\t<hr />\n",
            "\t\t\n",
            "\t\t<p>\n",
            "\t\t\tCreated with\n",
            "\t\t\t<a href=\"https://github.com/realm/SwiftLint\"><b>SwiftLint</b></a>\n",
            "\t\t\t", swiftlintVersion, " on ", dateString, "\n",
            "\t\t</p>\n",
            "\t</body>\n",
            "</html>"
        ].joined()
    }

    // MARK: - Private

    private static func generateSingleRow(for violation: StyleViolation, at index: Int) -> String {
        let severity: String = violation.severity.rawValue.capitalized
        let location = violation.location
        let file: String = (violation.location.relativeFile ?? "<nopath>").escapedForXML()
        let line: Int = location.line ?? 0
        let character: Int = location.character ?? 0
        return [
            "\t\t\t\t<tr>\n",
            "\t\t\t\t\t<td style=\"text-align: right;\">\(index)</td>\n",
            "\t\t\t\t\t<td>", file, "</td>\n",
            "\t\t\t\t\t<td style=\"text-align: center;\">\(line):\(character)</td>\n",
            "\t\t\t\t\t<td class=\"", severity.lowercased(), "\">", severity, "</td>\n",
            "\t\t\t\t\t<td>\(violation.reason.escapedForXML())</td>\n",
            "\t\t\t\t</tr>\n"
        ].joined()
    }
}
