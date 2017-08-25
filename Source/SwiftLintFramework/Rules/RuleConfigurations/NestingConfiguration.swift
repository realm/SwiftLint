//
//  NestingConfiguration.swift
//  SwiftLint
//
//  Created by 林達也 on 03/03/16.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation

public struct NestingConfiguration: RuleConfiguration, Equatable {
    private var typeLevelParameter: Parameter<SeverityLevelsConfiguration>
    private var statementLevelParameter: Parameter<SeverityLevelsConfiguration>
    public var parameters: [ParameterDefinition]

    public var typeLevel: SeverityLevelsConfiguration {
        return typeLevelParameter.value
    }

    public var statementLevel: SeverityLevelsConfiguration {
        return statementLevelParameter.value
    }

    public init(typeLevelWarning: Int,
                typeLevelError: Int?,
                statementLevelWarning: Int,
                statementLevelError: Int?) {
        let typeLevel = SeverityLevelsConfiguration(warning: typeLevelWarning, error: typeLevelError)
        let statementLevel = SeverityLevelsConfiguration(warning: statementLevelWarning, error: statementLevelError)

        typeLevelParameter = Parameter(key: "type_level", default: typeLevel, description: "")
        statementLevelParameter = Parameter(key: "statement_level", default: statementLevel, description: "")
        parameters = [typeLevelParameter, statementLevelParameter]
    }

    public mutating func apply(configuration: [String: Any]) throws {
        try typeLevelParameter.parse(from: configuration)
        try statementLevelParameter.parse(from: configuration)
    }

    func severity(with config: SeverityLevelsConfiguration, for level: Int) -> ViolationSeverity? {
        if let error = config.error, level > error {
            return .error
        } else if level > config.warning {
            return .warning
        }
        return nil
    }

    func threshold(with config: SeverityLevelsConfiguration, for severity: ViolationSeverity) -> Int {
        switch severity {
        case .error: return config.error ?? config.warning
        case .warning: return config.warning
        }
    }

    public static func == (lhs: NestingConfiguration, rhs: NestingConfiguration) -> Bool {
        return lhs.typeLevelParameter == rhs.typeLevelParameter
            && lhs.statementLevelParameter == rhs.statementLevelParameter
    }
}
