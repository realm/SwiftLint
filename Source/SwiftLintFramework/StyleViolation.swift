//
//  StyleViolation.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

public struct StyleViolation: CustomStringConvertible, Equatable {
    public let rule: Rule
    public let severity: ViolationSeverity
    public let location: Location
    public let reason: String?
    public var description: String {
        // {full_path_to_file}{:line}{:character}: {error,warning}: {content}
        return "\(location): " +
            "\(severity.rawValue.lowercaseString): " +
            "\(rule.dynamicType.name) Violation (\(severity) Severity): " +
            (reason ?? "")
    }

    public init(rule: Rule, location: Location, reason: String? = nil) {
        self.init(rule: rule, location: location, severity: .Warning, reason: reason)
    }

    public init(rule: Rule,
        location: Location,
        severity: ViolationSeverity,
        reason: String? = nil) {
        self.severity = severity
        self.rule = rule
        self.location = location
        self.reason = reason
    }
}

// MARK: Equatable

/**
Returns true if `lhs` StyleViolation is equal to `rhs` StyleViolation.

:param: lhs StyleViolation to compare to `rhs`.
:param: rhs StyleViolation to compare to `lhs`.

:returns: True if `lhs` StyleViolation is equal to `rhs` StyleViolation.
*/
public func == (lhs: StyleViolation, rhs: StyleViolation) -> Bool {
    return lhs.rule.identifier == rhs.rule.identifier &&
        lhs.location == rhs.location &&
        lhs.severity == rhs.severity &&
        lhs.reason == rhs.reason
}
