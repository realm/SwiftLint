//
//  XcodeReporter.swift
//  SwiftLint
//
//  Created by JP Simard on 9/19/15.
//  Copyright © 2015 Realm. All rights reserved.
//

public struct XcodeReporter: Reporter {
    public static let identifier = "xcode"
    public static let isRealtime = true

    public var description: String {
        return "Reports violations in the format Xcode uses to display in the IDE. (default)"
    }

    public static func generateReport(_ violations: [StyleViolation]) -> String {
        return violations.map(generateForSingleViolation).joined(separator: "\n")
    }

    internal static func generateForSingleViolation(_ violation: StyleViolation) -> String {
        // {full_path_to_file}{:line}{:character}: {error,warning}: {content}
        return [
            "\(violation.location): ",
            "\(violation.severity.rawValue): ",
            "\(violation.ruleDescription.name) Violation: ",
            violation.reason,
            " (\(violation.ruleDescription.identifier))"
        ].joined()
    }
}
