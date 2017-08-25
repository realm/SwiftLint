//
//  SeverityLevelsConfiguration.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/19/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct SeverityLevelsConfiguration: RuleConfiguration, Equatable {
    public let parameters: [ParameterDefinition]
    private(set) var warningParameter: Parameter<Int>
    private(set) var errorParameter: OptionalParameter<Int>

    var warning: Int {
        return warningParameter.value
    }

    var error: Int? {
        return errorParameter.value
    }

    public init(warning: Int, error: Int?) {
        warningParameter = Parameter(key: "warning",
                                     default: warning,
                                     description: "How serious")
        errorParameter = OptionalParameter(key: "error",
                                           default: error,
                                           description: "How serious")

        parameters = [warningParameter, errorParameter]
    }

    public mutating func apply(configuration: [String: Any]) throws {
        try warningParameter.parse(from: configuration)
        try errorParameter.parse(from: configuration)
    }

    var params: [RuleParameter<Int>] {
        if let error = error {
            return [RuleParameter(severity: .error, value: error),
                    RuleParameter(severity: .warning, value: warning)]
        }
        return [RuleParameter(severity: .warning, value: warning)]
    }
}

extension SeverityLevelsConfiguration: YamlLoadable {
    public static func load(from node: Any) throws -> SeverityLevelsConfiguration {
        guard let dict = node as? [String: Int] else {
            throw ConfigurationError.unknownConfiguration
        }

        var configuration = SeverityLevelsConfiguration(warning: 0, error: nil)
        try configuration.apply(configuration: dict)
        if configuration.warning == 0 {
            throw ConfigurationError.unknownConfiguration
        }

        return configuration
    }
}

public func == (lhs: SeverityLevelsConfiguration, rhs: SeverityLevelsConfiguration) -> Bool {
    return lhs.warning == rhs.warning && lhs.error == rhs.error
}
