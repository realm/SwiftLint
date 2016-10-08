//
//  StatementPositionConfiguration.swift
//  SwiftLint
//
//  Created by Michael Skiba on 6/8/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public enum StatmentModeConfiguration: String {
    case Default = "default", UncuddledElse = "uncuddled_else"

    init(value: Any) throws {
        if let string = (value as? String)?.lowercased(),
            let value = StatmentModeConfiguration(rawValue: string) {
            self = value
        } else {
            throw ConfigurationError.unknownConfiguration
        }
    }

}

public struct StatmentConfiguration: RuleConfiguration, Equatable {
    public var consoleDescription: String {
        return "(statement_mode) \(statementMode.rawValue), " +
            "(severity) \(severity.consoleDescription)"
    }

    var statementMode: StatmentModeConfiguration
    var severity: SeverityConfiguration

    public init(statementMode: StatmentModeConfiguration,
                severity: SeverityConfiguration) {
        self.statementMode = statementMode
        self.severity = severity
    }

    public mutating func applyConfiguration(_ configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }
        if let statementModeConfiguration = configurationDict["statement_mode"] {
            try statementMode = StatmentModeConfiguration(value: statementModeConfiguration)
        }
        if let severityConfiguration = configurationDict["severity"] {
            try severity.applyConfiguration(severityConfiguration)
        }
    }
}

public func == (lhs: StatmentConfiguration, rhs: StatmentConfiguration) -> Bool {
    return lhs.statementMode == rhs.statementMode && lhs.severity == rhs.severity
}
