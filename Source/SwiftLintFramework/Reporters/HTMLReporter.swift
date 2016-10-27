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
        return "Reports violations as Checkstyle XML."
    }

    public static func generateReport(violations: [StyleViolation]) -> String {
        var rows = ""
        for (index, violation) in violations.enumerate() {
            rows += generateSingleRow(for: violation, at: index + 1)
        }
        var HTML = HTMLTemplate()
        HTML = HTML.stringByReplacingOccurrencesOfString("__table_rows__", withString: rows)

        let bundle = NSBundle(identifier: "io.realm.SwiftLintFramework")!
        let version = bundle.objectForInfoDictionaryKey("CFBundleShortVersionString")
        let v = (version as? String ?? "0.0.0")
        HTML = HTML.stringByReplacingOccurrencesOfString("__version__", withString: v)

        let files = violations.map { violation in
            violation.location.file ?? ""
        }
        let uniqueFiles = Set(files)
        var countKey = "__number_of_files__"
        var count = "\(uniqueFiles.count)"
        HTML = HTML.stringByReplacingOccurrencesOfString(countKey, withString: count)

        let warnings = violations.filter { violation in
            violation.severity == .Warning
        }
        countKey = "__number_of_warnings__"
        count = "\(warnings.count)"
        HTML = HTML.stringByReplacingOccurrencesOfString(countKey, withString: count)

        let errors = violations.filter { violation in
            violation.severity == .Error
        }
        countKey = "__number_of_errors__"
        count = "\(errors.count)"
        HTML = HTML.stringByReplacingOccurrencesOfString(countKey, withString: count)

        let formatter = NSDateFormatter()
        formatter.dateStyle = .ShortStyle
        let dateString = formatter.stringFromDate(NSDate())
        HTML = HTML.stringByReplacingOccurrencesOfString("__report_date__", withString: dateString)

        return HTML
    }

    private static func generateSingleRow(for violation: StyleViolation, at index: Int) -> String {
        let severity = violation.severity.rawValue
        let location = violation.location
        return "<tr>" +
            "<td align=\"right\">\(index)</td>" +
            "<td>\(location.file ?? "")</td>" +
            "<td align=\"center\">\(location.line ?? 0):\(location.character ?? 0)</td>" +
            "<td class=\'\(severity.lowercaseString)\'>\(severity) </td>" +
            "<td>\(violation.reason)</td>" +
            "</tr>"
    }

    private static func HTMLTemplate() -> String {

        return "<!doctype html><html><head><title>Swiftlint Report</title><style type='text/css'>table { border: 1px solid gray; border-collapse: collapse; -moz-box-shadow: 3px 3px 4px #AAA; -webkit-box-shadow: 3px 3px 4px #AAA; box-shadow: 3px 3px 4px #AAA; } td, th { border: 1px solid #D3D3D3; padding: 5px 10px 5px 10px; } th { border-bottom: 1px solid gray; background-color: #29345C50; } .error, .warning {background-color: #f0f099;} .error{ color: #ff0000;} .warning { color: #b36b00;}</style></head><body><h1>Swiftlint Report</h1><hr /><h2>Violations</h2><table border=\"1\" style=\"vertical-align: top; height: 64px;\"><thead><tr><th style=\"width: 60pt;\"><b>Serial No.</b></th><th style=\"width: 500pt;\"><b>File</b></th><th style=\"width: 60pt;\"><b>Location</b></th><th style=\"width: 60pt;\"><b>Severity</b></th><th style=\"width: 500pt;\"><b>Message</b></th></tr></thead><tbody>__table_rows__</tbody></table><br/><h2>Summary</h2><table border=\"1\" style=\"vertical-align: top; height: 64px;\"><tbody><tr><td>Total files with violations</td><td>__number_of_files__</td></tr><tr><td>Total warnings</td><td>__number_of_warnings__</td></tr><tr><td>Total errors</td><td>__number_of_errors__</td></tr></tbody></table><hr /><p>Created with <a href=\"https://github.com/realm/SwiftLint\"><b>Swiftlint</b></a> __version__ on: __report_date__</p></body></html>"// swiftlint:disable:this line_length
    }
}
