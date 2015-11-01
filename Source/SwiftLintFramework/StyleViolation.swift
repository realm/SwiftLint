//
//  StyleViolation.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

public struct StyleViolation: CustomStringConvertible, Equatable {
    public let type: StyleViolationType
    public let severity: ViolationSeverity
    public let location: Location
    public let rule: Rule?
    public let reason: String?
    public var description: String {
        return XcodeReporter.generateForSingleViolation(self)
    }

    public init(type: StyleViolationType, location: Location,
        reason: String? = nil, rule: Rule? = nil) {
        self.init(type: type, location: location, severity: .Warning, reason: reason, rule: rule)
    }

    public init(type: StyleViolationType,
        location: Location,
        severity: ViolationSeverity,
        reason: String? = nil,
        rule: Rule? = nil) {
        self.severity = severity
        self.type = type
        self.location = location
        self.reason = reason
        self.rule = rule
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
    return lhs.type == rhs.type &&
        lhs.location == rhs.location &&
        lhs.severity == rhs.severity &&
        lhs.reason == rhs.reason
}
