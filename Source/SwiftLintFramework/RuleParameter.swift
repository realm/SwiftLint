//
//  RuleParameter.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

public struct RuleParameter<T> {
    public let severity: ViolationSeverity
    public let value: T

    public init(severity: ViolationSeverity, value: T) {
        self.severity = severity
        self.value = value
    }
}
