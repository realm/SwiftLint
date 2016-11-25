//
//  HTMLReporter.swift
//  SwiftLint
//
//  Created by Johnykutty on 10/27/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct HTMLReporter: Reporter {
    public static let identifier = "html"
    public static let isRealtime = false

    public var description: String {
        return "Reports violations as HTML"
    }

    // swiftlint:disable:next function_body_length
    public static func generateReport(violations: [StyleViolation]) -> String {
        var rows = ""
        for (index, violation) in violations.enumerate() {
            rows += generateSingleRow(for: violation, at: index + 1)
        }

        let bundle = NSBundle(identifier: "io.realm.SwiftLintFramework")!
        let version = bundle.objectForInfoDictionaryKey("CFBundleShortVersionString")
        let v = (version as? String ?? "0.0.0")

        let files = violations.map { violation in
            violation.location.file ?? ""
        }
        let uniqueFiles = Set(files)

        let warnings = violations.filter { violation in
            violation.severity == .Warning
        }

        let errors = violations.filter { violation in
            violation.severity == .Error
        }

        let formatter = NSDateFormatter()
        formatter.dateStyle = .ShortStyle
        let dateString = formatter.stringFromDate(NSDate())

        return "<!doctype html>\n" +
            "<html>\n" +
            "\t<head>\n" +
            "\t\t<title>Swiftlint Report</title>\n" +
            "\t\t<style type='text/css'>\n" +
            "\t\t\ttable {\n" +
            "\t\t\t\tborder: 1px solid gray;\n" +
            "\t\t\t\tborder-collapse: collapse;\n" +
            "\t\t\t\t-moz-box-shadow: 3px 3px 4px #AAA;\n" +
            "\t\t\t\t-webkit-box-shadow: 3px 3px 4px #AAA;\n" +
            "\t\t\t\tbox-shadow: 3px 3px 4px #AAA;\n" +
            "\t\t\t}\n" +
            "\t\ttd, th {\n" +
            "\t\t\t\tborder: 1px solid #D3D3D3;\n" +
            "\t\t\t\tpadding: 5px 10px 5px 10px;\n" +
            "\t\t}\n" +
            "\t\tth {\n" +
            "\t\t\tborder-bottom: 1px solid gray;\n" +
            "\t\t\tbackground-color: #29345C50;\n" +
            "\t\t}\n" +
            "\t\t.error, .warning {\n" +
            "\t\t\tbackground-color: #f0f099;\n" +
            "\t\t} .error{ color: #ff0000;}\n" +
            "\t\t.warning { color: #b36b00;\n" +
            "\t\t}\n" +
            "\t\t</style>\n" +
            "\t</head>\n" +
            "\t<body>\n" +
            "\t\t<h1>Swiftlint Report</h1>\n" +
            "\t\t<hr />\n" +
            "\t\t<h2>Violations</h2>\n" +
            "\t\t<table border=\"1\" style=\"vertical-align: top; height: 64px;\">\n" +
            "\t\t\t<thead>\n" +
            "\t\t\t\t<tr>\n" +
            "\t\t\t\t\t<th style=\"width: 60pt;\">\n" +
            "\t\t\t\t\t\t<b>Serial No.</b>\n" +
            "\t\t\t\t\t</th>\n" +
            "\t\t\t\t\t<th style=\"width: 500pt;\">\n" +
            "\t\t\t\t\t\t<b>File</b>\n" +
            "\t\t\t\t\t</th>\n" +
            "\t\t\t\t\t<th style=\"width: 60pt;\">\n" +
            "\t\t\t\t\t\t<b>Location</b>\n" +
            "\t\t\t\t\t</th>\n" +
            "\t\t\t\t\t<th style=\"width: 60pt;\">\n" +
            "\t\t\t\t\t\t<b>Severity</b>\n" +
            "\t\t\t\t\t</th>\n" +
            "\t\t\t\t\t<th style=\"width: 500pt;\">\n" +
            "\t\t\t\t\t\t<b>Message</b>\n" +
            "\t\t\t\t\t</th>\n" +
            "\t\t\t\t</tr>\n" +
            "\t\t\t</thead>\n" +
            "\t\t\t<tbody>\n" + rows + "\t\t\t</tbody>\n" +
            "\t\t</table>\n" +
            "\t\t<br/>\n" +
            "\t\t<h2>Summary</h2>\n" +
            "\t\t<table border=\"1\" style=\"vertical-align: top; height: 64px;\">\n" +
            "\t\t\t<tbody>\n" +
            "\t\t\t\t<tr>\n" +
            "\t\t\t\t\t<td>Total files with violations</td>\n" +
            "\t\t\t\t\t<td>\(uniqueFiles.count)</td>\n" +
            "\t\t\t\t</tr>\n" +
            "\t\t\t\t<tr>\n" +
            "\t\t\t\t\t<td>Total warnings</td>\n" +
            "\t\t\t\t\t<td>\(warnings.count)</td>\n" +
            "\t\t\t\t</tr>\n" +
            "\t\t\t\t<tr>\n" +
            "\t\t\t\t\t<td>Total errors</td>\n" +
            "\t\t\t\t\t<td>\(errors.count)</td>\n" +
            "\t\t\t\t</tr>\n" +
            "\t\t\t</tbody>\n" +
            "\t\t</table>\n" +
            "\t\t<hr />\n" +
            "\t\t<p>Created with <a href=\"https://github.com/realm/SwiftLint\">\n" +
            "\t\t\t<b>Swiftlint</b>\n" +
            "\t\t</a> " + v + " on: " + dateString + "</p>\n" +
            "\t</body>\n" +
        "</html>"
    }

    private static func generateSingleRow(for violation: StyleViolation, at index: Int) -> String {
        let severity = violation.severity.rawValue
        let location = violation.location
        let line = location.line ?? 0
        let character = location.character ?? 0
        return "\t\t\t\t<tr>\n" +
            "\t\t\t\t\t<td align=\"right\">\(index)</td>\n" +
            "\t\t\t\t\t<td>\(location.file ?? "")</td>\n" +
            "\t\t\t\t\t<td align=\"center\">\(line):\(character)</td>\n" +
            "\t\t\t\t\t<td class=\'\(severity.lowercaseString)\'>\(severity)</td>\n" +
            "\t\t\t\t\t<td>\(violation.reason)</td>\n" +
        "\t\t\t\t</tr>\n"
    }
}
