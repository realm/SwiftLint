//
//  StatementPositionConfiguration.swift
//  SwiftLint
//
//  Created by Michael Skiba on 6/8/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public enum StatementModeConfiguration: String, YamlLoadable {
    case `default` = "default"
    case uncuddledElse = "uncuddled_else"

    init(value: Any) throws {
        if let string = (value as? String)?.lowercased(),
            let value = StatementModeConfiguration(rawValue: string) {
            self = value
        } else {
            throw ConfigurationError.unknownConfiguration
        }
    }

}

public struct StatementConfiguration: RuleConfiguration, Equatable {
    public let parameters: [ParameterDefinition]
    private(set) var statementModeParameter: Parameter<StatementModeConfiguration>
    private(set) var severityParameter: Parameter<ViolationSeverity>

    var severity: ViolationSeverity {
        return severityParameter.value
    }

    var statementMode: StatementModeConfiguration {
        return statementModeParameter.value
    }

    public init(statementMode: StatementModeConfiguration,
                severity: ViolationSeverity) {
        statementModeParameter = Parameter(key: "statement_mode", default: statementMode, description: "")
        severityParameter = SeverityConfiguration(severity).severityParameter
        parameters = [statementModeParameter, severityParameter]
    }

    public mutating func apply(configuration: [String: Any]) throws {
        try statementModeParameter.parse(from: configuration)
        try severityParameter.parse(from: configuration)
    }

    public static func == (lhs: StatementConfiguration, rhs: StatementConfiguration) -> Bool {
        return lhs.statementMode == rhs.statementMode && lhs.severity == rhs.severity
    }
}
