//
//  TrailingCommaConfiguration.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 25/11/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct TrailingCommaConfiguration: RuleConfiguration, Equatable {
    public let parameters: [ParameterDefinition]
    private(set) var mandatoryCommaParameter: Parameter<Bool>
    private(set) var severityParameter = SeverityConfiguration(.warning).severityParameter

    var severity: ViolationSeverity {
        return severityParameter.value
    }

    var mandatoryComma: Bool {
        return mandatoryCommaParameter.value
    }

    public init(mandatoryComma: Bool = false) {
        mandatoryCommaParameter = Parameter(key: "mandatory_comma",
                                            default: mandatoryComma,
                                            description: "")
        parameters = [mandatoryCommaParameter, severityParameter]
    }

    public mutating func apply(configuration: [String: Any]) throws {
        try mandatoryCommaParameter.parse(from: configuration)
        try severityParameter.parse(from: configuration)
    }

    public static func == (lhs: TrailingCommaConfiguration,
                           rhs: TrailingCommaConfiguration) -> Bool {
        return lhs.mandatoryComma == rhs.mandatoryComma &&
            lhs.severityParameter == rhs.severityParameter
    }
}
