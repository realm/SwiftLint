//
//  JUnitReporter.swift
//  SwiftLint
//
//  Created by Matthew Ellis on 5/25/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct JUnitReporter: Reporter {
    public static let identifier = "junit"
    public static let isRealtime = false

    public var description: String {
        return "Reports violations as JUnit XML."
    }

    public static func generateReport(_ violations: [StyleViolation]) -> String {
        return "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n<testsuites><testsuite>" +
            violations.map({ violation in
                let fileName = (violation.location.file ?? "<nopath>").escapedForXML()
                let severity = violation.severity.rawValue + ":\n"
                let message = severity + "Line:" + String(violation.location.line ?? 0) + " "
                let reason = violation.reason.escapedForXML()
                return ["\n\t<testcase classname='Formatting Test' name='\(fileName)\'>\n",
                    "<failure message='\(reason)\'>" + message + "</failure>",
                    "\t</testcase>"].joined()
            }).joined() + "\n</testsuite></testsuites>"
    }
}
