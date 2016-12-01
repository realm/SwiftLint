//
//  EmojiReporter.swift
//  SwiftLint
//
//  Created by Michał Kałużny on 01/12/2016.
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
        return violations.group { (violation) in
                violation.location.file ?? "Other"
            }.map { (filename, violations) in
                return reportFor(file: filename, with: violations)
            }.joined(separator: "\n")
    }

    private static func reportFor(file: String, with violations: [StyleViolation]) -> String {
        var lines: [String] = []

        let sortedViolatons = violations.sorted { (lhs, rhs) -> Bool in
            switch (lhs.severity, rhs.severity) {
            case (.warning, .error): return false
            case (.error, .warning): return true
            case (_, _):
                switch (lhs.location.line, rhs.location.line) {
                case (.some(let lhs), .some(let rhs)): return lhs < rhs
                case (.some, .none): return true
                case (.none, .some): return false
                case (.none, .none): return false
                }
            }
        }

        lines.append(file)

        for violation in sortedViolatons {
            var line = ""
            line += emojiFor(violationSeverity: violation.severity)
            line += " "

            if let locationLine = violation.location.line {
                line += "Line \(locationLine): "
            }

            line += violation.reason

            lines.append(line)
        }

        return lines.joined(separator: "\n")
    }

    private static func emojiFor(violationSeverity: ViolationSeverity) -> String {
        switch violationSeverity {
        case .error:
            return "⛔️"
        case .warning:
            return "⚠️"
        }
    }
}
