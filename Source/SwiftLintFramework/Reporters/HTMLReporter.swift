//
//  HTMLReporter.swift
//  SwiftLint
//
//  Created by Johnykutty on 10/27/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private let formatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    return formatter
}()

private let swiftlintVersion = Bundle.swiftLintFramework
    .object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "0.0.0"

public struct HTMLReporter: Reporter {
    public static let identifier = "html"
    public static let isRealtime = false

    public var description: String {
        return "Reports violations as HTML"
    }

    private static let template: String = {
        let path = templatePath

        #if os(Linux)
            // swiftlint:disable:next force_try
            let data = try! Data(contentsOf: URL(fileURLWithPath: path))
            return String(data: data, encoding: .utf8)!
        #else
            // swiftlint:disable:next force_try
            return try! String(contentsOfFile: path)
        #endif
    }()

    private static var templatePath: String {
        #if SWIFT_PACKAGE
            let components = Array(NSString(string: #file).pathComponents.dropLast() + ["Templates", "template.html"])
            let path = components.joined(separator: "/")
        #else
            let bundle = Bundle.swiftLintFramework
            let path = bundle.path(forResource: "template", ofType: "html")!
        #endif

        return path
    }

    public static func generateReport(_ violations: [StyleViolation]) -> String {
        return generateReport(violations, swiftlintVersion: swiftlintVersion,
                              dateString: formatter.string(from: Date()))
    }

    internal static func generateReport(_ violations: [StyleViolation], swiftlintVersion: String,
                                        dateString: String) -> String {
        let rows = violations.enumerated().reduce("") { rows, indexAndViolation in
            return rows + generateSingleRow(for: indexAndViolation.1, at: indexAndViolation.0 + 1,
                                            initialIndentation: 16)
        }

        let fileCount = Set(violations.flatMap({ $0.location.file })).count
        let warningCount = violations.filter({ $0.severity == .warning }).count
        let errorCount = violations.filter({ $0.severity == .error }).count

        let parameters = [
            "VIOLATIONS": rows,
            "TOTAL_VIOLATING_FILES": String(fileCount),
            "TOTAL_WARNINGS": String(warningCount),
            "TOTAL_ERRORS": String(errorCount),
            "VERSION": swiftlintVersion,
            "DATE": dateString
        ]

        return generateReport(parameters: parameters)
    }

    private static func generateReport(parameters: [String: String]) -> String {
        var report = template
        for (key, value) in parameters {
            report = report.replacingOccurrences(of: "$$\(key)$$", with: value)
        }

        return report
    }

    private static func generateSingleRow(for violation: StyleViolation, at index: Int,
                                          initialIndentation: Int) -> String {
        let severity: String = violation.severity.rawValue.capitalized
        let location = violation.location
        let file: String = (violation.location.relativeFile ?? "<nopath>").escapedForXML()
        let line: Int = location.line ?? 0
        let character: Int = location.character ?? 0
        let indentation = String(repeating: " ", count: initialIndentation)
        return [
            "<tr>\n",
            "    <td style=\"text-align: right;\">\(index)</td>\n",
            "    <td>\(file)</td>\n",
            "    <td style=\"text-align: center;\">\(line):\(character)</td>\n",
            "    <td class=\"\(severity.lowercased())\">\(severity)</td>\n",
            "    <td>\(violation.reason.escapedForXML())</td>\n",
            "</tr>\n"
        ].map { indentation + $0 }.joined()
    }
}
