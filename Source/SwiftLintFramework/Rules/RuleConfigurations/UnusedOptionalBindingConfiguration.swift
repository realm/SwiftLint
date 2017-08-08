//
//  UnusedOptionalBindingConfiguration.swift
//  SwiftLint
//
//  Created by Sergey Galezdinov on 23/04/17.
//  Copyright © 2017 Realm. All rights reserved.
//

public struct UnusedOptionalBindingConfiguration: RuleConfiguration, Equatable {
    public let parameters: [ParameterDefinition]
    private(set) var ignoreOptionalTryParameter: Parameter<Bool>
    private(set) var severityParameter = SeverityConfiguration(.warning).severityParameter

    var severity: ViolationSeverity {
        return severityParameter.value
    }

    var ignoreOptionalTry: Bool {
        return ignoreOptionalTryParameter.value
    }

    public init(ignoreOptionalTry: Bool) {
        ignoreOptionalTryParameter = Parameter(key: "ignore_optional_try",
                                               default: ignoreOptionalTry,
                                               description: "")
        parameters = [ignoreOptionalTryParameter, severityParameter]
    }

    public mutating func apply(configuration: [String: Any]) throws {
        try ignoreOptionalTryParameter.parse(from: configuration)
        try severityParameter.parse(from: configuration)
    }

    public static func == (lhs: UnusedOptionalBindingConfiguration,
                           rhs: UnusedOptionalBindingConfiguration) -> Bool {
        return lhs.ignoreOptionalTry == rhs.ignoreOptionalTry &&
            lhs.severity == rhs.severity
    }
}
