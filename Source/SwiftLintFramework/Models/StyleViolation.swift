//
//  StyleViolation.swift
//  SwiftLint
//
//  Created by JP Simard on 5/16/15.
//  Copyright © 2015 Realm. All rights reserved.
//

public struct StyleViolation: CustomStringConvertible, Equatable {
    public let ruleDescription: RuleDescription
    public let severity: ViolationSeverity
    public let location: Location
    public let reason: String
    public var description: String {
        return XcodeReporter.generateForSingleViolation(self)
    }

    public init(ruleDescription: RuleDescription, severity: ViolationSeverity = .warning,
                location: Location, reason: String? = nil) {
        self.ruleDescription = ruleDescription
        self.severity = severity
        self.location = location
        self.reason = reason ?? ruleDescription.description
    }
}

// MARK: Equatable

public func == (lhs: StyleViolation, rhs: StyleViolation) -> Bool {
    return lhs.ruleDescription == rhs.ruleDescription &&
        lhs.location == rhs.location &&
        lhs.severity == rhs.severity &&
        lhs.reason == rhs.reason
}
