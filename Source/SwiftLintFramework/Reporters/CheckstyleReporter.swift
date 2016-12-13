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
            violations.map(generateForSingleViolation).joined(),
            "\n</checkstyle>"
        ].joined()
    }

    private static func generateForSingleViolation(_ violation: StyleViolation) -> String {
        let file: String = (violation.location.file ?? "<nopath>").escapedForXml()
        let line: Int = violation.location.line ?? 0
        let col: Int = violation.location.character ?? 0
        let severity: String = violation.severity.rawValue
        let reason: String = violation.reason.escapedForXml()
        return [
            "\n\t<file name=\"", file, "\">\n",
            "\t\t<error line=\"\(line)\" ",
            "column=\"\(col)\" ",
            "severity=\"", severity, "\" ",
            "message=\"", reason, "\"/>\n",
            "\t</file>"
        ].joined()
    }
}
