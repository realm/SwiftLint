//
//  CSVReporter.swift
//  SwiftLint
//
//  Created by JP Simard on 9/19/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation

private extension String {
    func escapedForCSV() -> String {
        let escapedString = replacingOccurrences(of: "\"", with: "\"\"")
        if escapedString.contains(",") || escapedString.contains("\n") {
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

    public static func generateReport(_ violations: [StyleViolation]) -> String {
        let keys = [
            "file",
            "line",
            "character",
            "severity",
            "type",
            "reason",
            "rule_id"
        ].joined(separator: ",")

        let rows = [keys] + violations.flatMap(csvRow(for:))
        return rows.joined(separator: "\n")
    }

    fileprivate static func csvRow(for violation: StyleViolation) -> String {
        return [
            violation.location.file?.escapedForCSV() ?? "",
            violation.location.line?.description ?? "",
            violation.location.character?.description ?? "",
            violation.severity.rawValue.capitalized,
            violation.ruleDescription.name.escapedForCSV(),
            violation.reason.escapedForCSV(),
            violation.ruleDescription.identifier
        ].joined(separator: ",")
    }
}
