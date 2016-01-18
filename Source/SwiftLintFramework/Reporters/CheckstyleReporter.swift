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

    public static func generateReport(violations: [StyleViolation]) -> String {
        return "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<checkstyle version=\"4.3\">" +
            violations.map({ violation in
                let fileName = violation.location.file ?? "<nopath>"
                return ["\n\t<file name=\"\(fileName)\">\n",
                    "\t\t<error line=\"\(violation.location.line ?? 0)\" ",
                    "column=\"\(violation.location.character ?? 0)\" ",
                    "severity=\"\(violation.severity.rawValue.lowercaseString)\" ",
                    "message=\"\(violation.reason)\"/>\n",
                    "\t</file>"].joinWithSeparator("")
            }).joinWithSeparator("") + "\n</checkstyle>"
    }
}
