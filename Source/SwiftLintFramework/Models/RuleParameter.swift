//
//  RuleParameter.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

public struct RuleParameter<T: Equatable> : Equatable {
    public let severity: ViolationSeverity
    public let value: T

    public init(severity: ViolationSeverity, value: T) {
        self.severity = severity
        self.value = value
    }
}

// MARK: - Equatable

public func ==<T: Equatable>(lhs: RuleParameter<T>, rhs: RuleParameter<T>) -> Bool {
    return lhs.value == rhs.value && lhs.severity == rhs.severity
}
