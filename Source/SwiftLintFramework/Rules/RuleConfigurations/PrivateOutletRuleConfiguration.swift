//
//  PrivateOutletRuleConfiguration.swift
//  SwiftLint
//
//  Created by Rohan Dhaimade on 24/8/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct PrivateOutletRuleConfiguration: RuleConfiguration, Equatable {
    private(set) var allowPrivateSetParameter: Parameter<Bool>
    private(set) var severityParameter = SeverityConfiguration(.warning).severityParameter

    public var severity: ViolationSeverity {
        return severityParameter.value
    }

    public var allowPrivateSet: Bool {
        return allowPrivateSetParameter.value
    }

    public init(allowPrivateSet: Bool = false) {
        allowPrivateSetParameter = Parameter(key: "allow_private_set",
                                             default: allowPrivateSet,
                                             description: "How serious")
    }

    public mutating func apply(configuration: [String: Any]) throws {
        try allowPrivateSetParameter.parse(from: configuration)
        try severityParameter.parse(from: configuration)
    }

    static public func == (lhs: PrivateOutletRuleConfiguration,
                           rhs: PrivateOutletRuleConfiguration) -> Bool {
        return lhs.allowPrivateSet == rhs.allowPrivateSet &&
            lhs.severity == rhs.severity
    }
}
