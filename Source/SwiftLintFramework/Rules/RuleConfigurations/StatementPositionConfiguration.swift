//
//  StatementPositionConfiguration.swift
//  SwiftLint
//
//  Created by Michael Skiba on 6/8/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public enum StatmentModeConfiguration: String {
    case Standard, UncuddledElse

    init(value: AnyObject) throws {
        guard let string = (value as? String)?.lowercaseString else {
            throw ConfigurationError.UnknownConfiguration
        }
        if string == StatmentModeConfiguration.Standard.rawValue.lowercaseString {
            self = .Standard
        } else if string == StatmentModeConfiguration.UncuddledElse.rawValue.lowercaseString {
            self = .UncuddledElse
        } else {
            throw ConfigurationError.UnknownConfiguration
        }
    }

}

public struct StatmentConfiguration: RuleConfiguration, Equatable {
    public var consoleDescription: String {
        return "(statement mode) \(statementMode.rawValue), " +
            "(severity) \(severity.consoleDescription)"
    }

    var statementMode: StatmentModeConfiguration
    var severity: SeverityConfiguration

    public init(statementMode: StatmentModeConfiguration,
                severity: SeverityConfiguration) {
        self.statementMode = statementMode
        self.severity = severity
    }

    public mutating func applyConfiguration(configuration: AnyObject) throws {
        guard let configurationDict = configuration as? [String: AnyObject] else {
            throw ConfigurationError.UnknownConfiguration
        }
        if let statementModeConfiguration = configurationDict["statementMode"] {
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
