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

    public var description: String {
        return "Reports violations as a JSON array."
    }

    public static func generateReport(violations: [StyleViolation]) -> String {
        return toJSON(violations.map(dictionaryForViolation))
    }

    private static func dictionaryForViolation(violation: StyleViolation) -> NSDictionary {
        return [
            "file": violation.location.file ?? NSNull(),
            "line": violation.location.line ?? NSNull(),
            "character": violation.location.character ?? NSNull(),
            "severity": violation.severity.rawValue,
            "type": violation.type.description,
            "reason": violation.reason ?? NSNull()
        ]
    }
}
