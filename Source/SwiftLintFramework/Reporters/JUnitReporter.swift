//
//  JUnitReporter.swift
//  SwiftLint
//
//  Created by Matthew Ellis on 25/05/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct JUnitReporter: Reporter {
    public static let identifier = "junit"
    public static let isRealtime = false

    public var description: String {
        return "Reports violations as JUnit XML."
    }

    public static func generateReport(violations: [StyleViolation]) -> String {
        return "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<testsuites><testsuite>" +
            violations.map({ violation in
                let fileName = violation.location.file ?? "<nopath>"
                let severity = violation.severity.rawValue.lowercaseString + ":\n"
                let message = severity + "Line:" + String(violation.location.line ?? 0) + " "
                return ["\n\t<testcase classname='Formatting Test' name='\(fileName)\'>\n",
                    "<failure message='\(violation.reason)\'>" + message + "</failure>",
                    "\t</testcase>"].joinWithSeparator("")
            }).joinWithSeparator("") + "\n</testsuite></testsuites>"
    }
}
