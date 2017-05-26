//
//  CheckstyleReporter.swift
//  SwiftLint
//
//  Created by JP Simard on 12/25/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation

public struct CheckstyleReporter: Reporter {
    public static let identifier = "checkstyle"
    public static let isRealtime = false

    public var description: String {
        return "Reports violations as Checkstyle XML."
    }

    public static func generateReport(_ violations: [StyleViolation]) -> String {
        return [
            "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<checkstyle version=\"4.3\">",
            violations
                .group(by: { ($0.location.file ?? "<nopath>").escapedForXML() })
                .sorted(by: { $0.key < $1.key })
                .map({ generateForViolationFile($0.0, violations: $0.1) }).joined(),
            "\n</checkstyle>"
        ].joined()
    }

    private static func generateForViolationFile(_ file: String, violations: [StyleViolation]) -> String {
        return [
            "\n\t<file name=\"", file, "\">\n",
            violations.map(generateForSingleViolation).joined(),
            "\t</file>"
        ].joined()
    }

    private static func generateForSingleViolation(_ violation: StyleViolation) -> String {
        let line: Int = violation.location.line ?? 0
        let col: Int = violation.location.character ?? 0
        let severity: String = violation.severity.rawValue
        let reason: String = violation.reason.escapedForXML()
        let identifier: String = violation.ruleDescription.identifier
        let source: String = "swiftlint.rules.\(identifier)".escapedForXML()
        return [
            "\t\t<error line=\"\(line)\" ",
            "column=\"\(col)\" ",
            "severity=\"", severity, "\" ",
            "message=\"", reason, "\" ",
            "source=\"\(source)\"/>\n"
        ].joined()
    }
}
