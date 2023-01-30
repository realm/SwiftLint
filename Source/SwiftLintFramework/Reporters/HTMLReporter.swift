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
        let rows = violations.enumerated()
            .map { generateSingleRow(for: $1, at: $0 + 1) }
            .joined(separator: "\n")

        let fileCount = Set(violations.compactMap({ $0.location.file })).count
        let warningCount = violations.filter({ $0.severity == .warning }).count
        let errorCount = violations.filter({ $0.severity == .error }).count

        return """
            <!doctype html>
            <html>
            \t<head>
            \t\t<meta charset="utf-8" />
            \t\t<meta name="viewport" content="width=device-width, initial-scale=1.0" />
            \t\t
            \t\t<style type="text/css">
            \t\t\tbody {
            \t\t\t\tfont-family: Arial, Helvetica, sans-serif;
            \t\t\t\tfont-size: 0.9rem;
            \t\t\t}
            \t\t\t
            \t\t\ttable {
            \t\t\t\tborder: 1px solid gray;
            \t\t\t\tborder-collapse: collapse;
            \t\t\t\t-moz-box-shadow: 3px 3px 4px #AAA;
            \t\t\t\t-webkit-box-shadow: 3px 3px 4px #AAA;
            \t\t\t\tbox-shadow: 3px 3px 4px #AAA;
            \t\t\t\tvertical-align: top;
            \t\t\t\theight: 64px;
            \t\t\t}
            \t\t\t
            \t\t\ttd, th {
            \t\t\t\tborder: 1px solid #D3D3D3;
            \t\t\t\tpadding: 5px 10px 5px 10px;
            \t\t\t}
            \t\t\t
            \t\t\tth {
            \t\t\t\tborder-bottom: 1px solid gray;
            \t\t\t\tbackground-color: rgba(41,52,92,0.313);
            \t\t\t}
            \t\t\t
            \t\t\t.error, .warning {
            \t\t\t\ttext-align: center;
            \t\t\t}
            \t\t\t
            \t\t\t.error {
            \t\t\t\tbackground-color: #FF9D92;
            \t\t\t\tcolor: #7F0800;
            \t\t\t}
            \t\t\t
            \t\t\t.warning {
            \t\t\t\tbackground-color: #FFF59E;
            \t\t\t\tcolor: #7F7000;
            \t\t\t}
            \t\t</style>
            \t\t
            \t\t<title>SwiftLint Report</title>
            \t</head>
            \t<body>
            \t\t<h1>SwiftLint Report</h1>
            \t\t
            \t\t<hr />
            \t\t
            \t\t<h2>Violations</h2>
            \t\t
            \t\t<table>
            \t\t\t<thead>
            \t\t\t\t<tr>
            \t\t\t\t\t<th style="width: 60pt;">
            \t\t\t\t\t\t<b>Serial No.</b>
            \t\t\t\t\t</th>
            \t\t\t\t\t<th style="width: 500pt;">
            \t\t\t\t\t\t<b>File</b>
            \t\t\t\t\t</th>
            \t\t\t\t\t<th style="width: 60pt;">
            \t\t\t\t\t\t<b>Location</b>
            \t\t\t\t\t</th>
            \t\t\t\t\t<th style="width: 60pt;">
            \t\t\t\t\t\t<b>Severity</b>
            \t\t\t\t\t</th>
            \t\t\t\t\t<th style="width: 500pt;">
            \t\t\t\t\t\t<b>Message</b>
            \t\t\t\t\t</th>
            \t\t\t\t</tr>
            \t\t\t</thead>
            \t\t\t<tbody>
            \(rows)
            \t\t\t</tbody>
            \t\t</table>
            \t\t
            \t\t<br/>
            \t\t
            \t\t<h2>Summary</h2>
            \t\t
            \t\t<table>
            \t\t\t<tbody>
            \t\t\t\t<tr>
            \t\t\t\t\t<td>Total files with violations</td>
            \t\t\t\t\t<td>\(fileCount)</td>
            \t\t\t\t</tr>
            \t\t\t\t<tr>
            \t\t\t\t\t<td>Total warnings</td>
            \t\t\t\t\t<td>\(warningCount)</td>
            \t\t\t\t</tr>
            \t\t\t\t<tr>
            \t\t\t\t\t<td>Total errors</td>
            \t\t\t\t\t<td>\(errorCount)</td>
            \t\t\t\t</tr>
            \t\t\t</tbody>
            \t\t</table>
            \t\t
            \t\t<hr />
            \t\t
            \t\t<p>
            \t\t\tCreated with
            \t\t\t<a href="https://github.com/realm/SwiftLint"><b>SwiftLint</b></a>
            \t\t\t\(swiftlintVersion) on \(dateString)
            \t\t</p>
            \t</body>
            </html>
            """
    }

    // MARK: - Private

    private static func generateSingleRow(for violation: StyleViolation, at index: Int) -> String {
        let severity: String = violation.severity.rawValue.capitalized
        let location = violation.location
        let file: String = (violation.location.relativeFile ?? "<nopath>").escapedForXML()
        let line: Int = location.line ?? 0
        let character: Int = location.character ?? 0
        return """
            \t\t\t\t<tr>
            \t\t\t\t\t<td style="text-align: right;">\(index)</td>
            \t\t\t\t\t<td>\(file)</td>
            \t\t\t\t\t<td style="text-align: center;">\(line):\(character)</td>
            \t\t\t\t\t<td class="\(severity.lowercased())">\(severity)</td>
            \t\t\t\t\t<td>\(violation.reason.escapedForXML())</td>
            \t\t\t\t</tr>
            """
    }
}
