//
//  SeverityConfiguration.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/20/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct SeverityConfiguration: RuleConfiguration, Equatable {
    public let parameters: [ParameterDefinition]
    private(set) var severityParameter: Parameter<ViolationSeverity>

    var severity: ViolationSeverity {
        return severityParameter.value
    }

    public init(_ severity: ViolationSeverity) {
        severityParameter = Parameter(key: "severity",
                                      default: severity,
                                      description: "How serious")
        parameters = [severityParameter]
    }

    public mutating func apply(configuration: [String: Any]) throws {
        try severityParameter.parse(from: configuration)
    }
}

public func == (lhs: SeverityConfiguration, rhs: SeverityConfiguration) -> Bool {
    return lhs.severity == rhs.severity
}
