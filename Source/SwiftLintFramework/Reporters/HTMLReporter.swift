//
//  HTMLReporter.swift
//  SwiftLint
//
//  Created by Johnykutty on 10/27/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

private let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    return formatter
}()

private let swiftlintVersion = Bundle(identifier: "io.realm.SwiftLintFramework")?
    .object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"

public struct HTMLReporter: Reporter {
    public static let identifier = "html"
    public static let isRealtime = false

    public var description: String {
        return "Reports violations as HTML"
    }

    public static func generateReport(_ violations: [StyleViolation]) -> String {
        let dateString = formatter.string(from: Date())
        return generateReport(
                violations,
                swiftlintVersion: swiftlintVersion,
                dateString: dateString
        )
    }

    // swiftlint:disable function_body_length
    // swiftlint:disable line_length
    internal static func generateReport(_ violations: [StyleViolation], swiftlintVersion: String, dateString: String) -> String {
        let rows = violations.enumerated().reduce("") { rows, indexAndViolation in
            return rows + generateSingleRow(for: indexAndViolation.1, at: indexAndViolation.0 + 1)
        }

        let fileCount = Set(violations.flatMap({ $0.location.file })).count
        let warningCount = violations.filter({ $0.severity == .warning }).count
        let errorCount = violations.filter({ $0.severity == .error }).count

        return [
            "<!doctype html>\n",
            "<html>\n",
            "\t<head>\n",
            "\t\t<title>Swiftlint Report</title>\n",
            "\t\t<style type='text/css'>\n",
            "\t\t\ttable {\n",
            "\t\t\t\tborder: 1px solid gray;\n",
            "\t\t\t\tborder-collapse: collapse;\n",
            "\t\t\t\t-moz-box-shadow: 3px 3px 4px #AAA;\n",
            "\t\t\t\t-webkit-box-shadow: 3px 3px 4px #AAA;\n",
            "\t\t\t\tbox-shadow: 3px 3px 4px #AAA;\n",
            "\t\t\t}\n",
            "\t\ttd, th {\n",
            "\t\t\t\tborder: 1px solid #D3D3D3;\n",
            "\t\t\t\tpadding: 5px 10px 5px 10px;\n",
            "\t\t}\n",
            "\t\tth {\n",
            "\t\t\tborder-bottom: 1px solid gray;\n",
            "\t\t\tbackground-color: #29345C50;\n",
            "\t\t}\n",
            "\t\t.error, .warning {\n",
            "\t\t\tbackground-color: #f0f099;\n",
            "\t\t} .error{ color: #ff0000;}\n",
            "\t\t.warning { color: #b36b00;\n",
            "\t\t}\n",
            "\t\t</style>\n",
            "\t</head>\n",
            "\t<body>\n",
            "\t\t<h1>Swiftlint Report</h1>\n",
            "\t\t<hr />\n",
            "\t\t<h2>Violations</h2>\n",
            "\t\t<table border=\"1\" style=\"vertical-align: top; height: 64px;\">\n",
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
            "\t\t<br/>\n",
            "\t\t<h2>Summary</h2>\n",
            "\t\t<table border=\"1\" style=\"vertical-align: top; height: 64px;\">\n",
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
            "\t\t<hr />\n",
            "\t\t<p>Created with <a href=\"https://github.com/realm/SwiftLint\">\n",
            "\t\t\t<b>Swiftlint</b>\n",
            "\t\t</a> ", swiftlintVersion, " on: ", dateString, "</p>\n",
            "\t</body>\n",
            "</html>"
        ].joined()
    }

    private static func generateSingleRow(for violation: StyleViolation, at index: Int) -> String {
        let severity: String = violation.severity.rawValue.capitalized
        let location = violation.location
        let file: String = (violation.location.file ?? "<nopath>").escapedForXml()
        let line: Int = location.line ?? 0
        let character: Int = location.character ?? 0
        return [
            "\t\t\t\t<tr>\n",
            "\t\t\t\t\t<td align=\"right\">\(index)</td>\n",
            "\t\t\t\t\t<td>", file, "</td>\n",
            "\t\t\t\t\t<td align=\"center\">\(line):\(character)</td>\n",
            "\t\t\t\t\t<td class=\'", severity.lowercased(), "\'>", severity, "</td>\n",
            "\t\t\t\t\t<td>\(violation.reason.escapedForXml())</td>\n",
            "\t\t\t\t</tr>\n"
        ].joined()
    }
}
