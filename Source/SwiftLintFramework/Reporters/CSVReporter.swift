//
//  CSVReporter.swift
//  SwiftLint
//
//  Created by JP Simard on 9/19/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation

extension String {
    private func escapedForCSV() -> String {
        let escapedString = stringByReplacingOccurrencesOfString("\"", withString: "\"\"")
        if escapedString.containsString(",") || escapedString.containsString("\n") {
            return "\"\(escapedString)\""
        }
        return escapedString
    }
}

public struct CSVReporter: Reporter {
    public static let identifier = "csv"
    public static let isRealtime = false

    public var description: String {
        return "Reports violations as a newline-separated string of comma-separated values (CSV)."
    }

    public static func generateReport(violations: [StyleViolation]) -> String {
        let keys = [
            "file",
            "line",
            "character",
            "severity",
            "type",
            "reason",
            "rule_id"
        ]
        return (keys + violations.flatMap(arrayForViolation)).joinWithSeparator(",")
    }

    private static func arrayForViolation(violation: StyleViolation) -> [String] {
        let values: [AnyObject?] = [
            violation.location.file?.escapedForCSV(),
            violation.location.line,
            violation.location.character,
            violation.severity.rawValue,
            violation.ruleDescription.name.escapedForCSV(),
            violation.reason.escapedForCSV(),
            violation.ruleDescription.identifier
        ]
        return values.map({ $0?.description ?? "" })
    }
}
