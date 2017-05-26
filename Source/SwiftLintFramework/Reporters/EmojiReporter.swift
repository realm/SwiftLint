//
//  EmojiReporter.swift
//  SwiftLint
//
//  Created by Michał Kałużny on 12/01/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct EmojiReporter: Reporter {
    public static let identifier = "emoji"
    public static let isRealtime = false

    public var description: String {
        return "Reports violations in the format that's both fun and easy to read."
    }

    public static func generateReport(_ violations: [StyleViolation]) -> String {
        return violations
            .group(by: { $0.location.file ?? "Other" })
            .sorted(by: { $0.key < $1.key })
            .map({ report(for: $0.0, with: $0.1) })
            .joined(separator: "\n")
    }

    private static func report(for file: String, with violations: [StyleViolation]) -> String {
        let lines = [file] + violations.sorted(by: { lhs, rhs in
            guard lhs.severity == rhs.severity else {
                return lhs.severity > rhs.severity
            }
            return lhs.location > rhs.location
        }).map { violation in
            let emoji = (violation.severity == .error) ? "⛔️" : "⚠️"
            let lineString: String
            if let line = violation.location.line {
                lineString = "Line \(line): "
            } else {
                lineString = ""
            }
            return "\(emoji) \(lineString)\(violation.reason)"
        }
        return lines.joined(separator: "\n")
    }
}
