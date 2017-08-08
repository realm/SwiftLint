//
//  PrivateOverFilePrivateRuleConfiguration.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 08/01/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation

public struct PrivateOverFilePrivateRuleConfiguration: RuleConfiguration, Equatable {
    public let parameters: [ParameterDefinition]
    private var validateExtensionsParameter: Parameter<Bool>
    private var severityParameter = SeverityConfiguration(.warning).severityParameter

    var severity: ViolationSeverity {
        return severityParameter.value
    }

    var validateExtensions: Bool {
        return validateExtensionsParameter.value
    }

    public init(validateExtensions: Bool = false) {
        validateExtensionsParameter = Parameter(key: "validate_extensions",
                                                default: validateExtensions,
                                                description: "How serious")

        parameters = [validateExtensionsParameter, severityParameter]
    }

    public mutating func apply(configuration: [String: Any]) throws {
        try validateExtensionsParameter.parse(from: configuration)
        try severityParameter.parse(from: configuration)
    }

    // MARK: - Equatable

    public static func == (lhs: PrivateOverFilePrivateRuleConfiguration,
                           rhs: PrivateOverFilePrivateRuleConfiguration) -> Bool {
        return lhs.validateExtensions == rhs.validateExtensions &&
            lhs.severity == rhs.severity
    }
}
