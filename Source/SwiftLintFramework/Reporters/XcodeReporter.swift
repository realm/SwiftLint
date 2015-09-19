//
//  XcodeReporter.swift
//  SwiftLint
//
//  Created by JP Simard on 9/19/15.
//  Copyright © 2015 Realm. All rights reserved.
//

public struct XcodeReporter: Reporter {
    public static let identifier = "xcode"

    public var description: String {
        return "Reports violations in the format Xcode uses to display in the IDE. (default)"
    }

    public static func generateReport(violations: [StyleViolation]) -> String {
        return violations.map(generateForSingleViolation).joinWithSeparator("\n")
    }

    internal static func generateForSingleViolation(violation: StyleViolation) -> String {
        // {full_path_to_file}{:line}{:character}: {error,warning}: {content}
        return "\(violation.location): " +
            "\(violation.severity.rawValue.lowercaseString): " +
            "\(violation.type) Violation: " +
            (violation.reason ?? "")
    }
}
