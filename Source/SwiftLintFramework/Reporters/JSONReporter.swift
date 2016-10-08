//
//  JSONReporter.swift
//  SwiftLint
//
//  Created by JP Simard on 9/19/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct JSONReporter: Reporter {
    public static let identifier = "json"
    public static let isRealtime = false

    public var description: String {
        return "Reports violations as a JSON array."
    }

    public static func generateReport(_ violations: [StyleViolation]) -> String {
        return toJSON(violations.map(dictionaryForViolation))
    }

    fileprivate static func dictionaryForViolation(_ violation: StyleViolation) -> NSDictionary {
        let result: [String: Any] = [
            "file": violation.location.file,
            "line": violation.location.line,
            "character": violation.location.character,
            "severity": violation.severity.rawValue,
            "type": violation.ruleDescription.name,
            "rule_id": violation.ruleDescription.identifier,
            "reason": violation.reason
        ]
        return result as NSDictionary
    }
}
