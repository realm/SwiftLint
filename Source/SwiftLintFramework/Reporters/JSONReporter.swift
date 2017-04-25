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
        return toJSON(violations.map(dictionary(for:)))
    }

    fileprivate static func dictionary(for violation: StyleViolation) -> [String: Any] {
        return [
            "file": violation.location.file ?? NSNull() as Any,
            "line": violation.location.line ?? NSNull() as Any,
            "character": violation.location.character ?? NSNull() as Any,
            "severity": violation.severity.rawValue.capitalized,
            "type": violation.ruleDescription.name,
            "rule_id": violation.ruleDescription.identifier,
            "reason": violation.reason
        ]
    }
}
