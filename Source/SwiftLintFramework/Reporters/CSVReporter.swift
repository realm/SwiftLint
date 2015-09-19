//
//  CSVReporter.swift
//  SwiftLint
//
//  Created by JP Simard on 9/19/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation

public struct CSVReporter: Reporter {
    public static let identifier = "csv"

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
            "reason"
        ]
        return (keys + violations.flatMap(arrayForViolation)).joinWithSeparator(",")
    }

    private static func arrayForViolation(violation: StyleViolation) -> [String] {
        let values: [AnyObject?] = [
            violation.location.file,
            violation.location.line,
            violation.location.character,
            violation.severity.rawValue,
            violation.type.description,
            violation.reason
        ]
        return values.map({ $0?.description ?? "" })
    }
}
