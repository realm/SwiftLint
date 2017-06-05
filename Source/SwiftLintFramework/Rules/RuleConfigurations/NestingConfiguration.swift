//
//  NestingConfiguration.swift
//  SwiftLint
//
//  Created by 林達也 on 03/03/16.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation

public struct NestingConfiguration: RuleConfiguration, Equatable {
    public var consoleDescription: String {
        return "(type_level) \(typeLevel.shortConsoleDescription), " +
            "(statement_level) \(statementLevel.shortConsoleDescription)"
    }

    var typeLevel: SeverityLevelsConfiguration
    var statementLevel: SeverityLevelsConfiguration

    public init(typeLevelWarning: Int,
                typeLevelError: Int?,
                statementLevelWarning: Int,
                statementLevelError: Int?) {
        typeLevel = SeverityLevelsConfiguration(warning: typeLevelWarning, error: typeLevelError)
        statementLevel = SeverityLevelsConfiguration(warning: statementLevelWarning, error: statementLevelError)
    }

    public mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let typeLevelConfiguration = configurationDict["type_level"] {
            try typeLevel.apply(configuration: typeLevelConfiguration)
        }
        if let statementLevelConfiguration = configurationDict["statement_level"] {
            try statementLevel.apply(configuration: statementLevelConfiguration)
        }
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
}

public func == (lhs: NestingConfiguration, rhs: NestingConfiguration) -> Bool {
    return lhs.typeLevel == rhs.typeLevel
        && lhs.statementLevel == rhs.statementLevel
}
