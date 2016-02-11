//
//  NameConfig.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/19/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct NameConfig: RuleConfiguration, Equatable {
    public var consoleDescription: String {
        return "(min_length) \(minLength.shortConsoleDescription), " +
            "(max_length) \(maxLength.shortConsoleDescription)"
    }

    var minLength: SeverityLevelsConfig
    var maxLength: SeverityLevelsConfig
    var excluded: Set<String>

    var minLengthThreshold: Int {
        return max(minLength.warning, minLength.error ?? minLength.warning)
    }

    var maxLengthThreshold: Int {
        return min(maxLength.warning, maxLength.error ?? maxLength.warning)
    }

    public init(minLengthWarning: Int,
                minLengthError: Int,
                maxLengthWarning: Int,
                maxLengthError: Int,
                excluded: [String] = []) {
        minLength = SeverityLevelsConfig(warning: minLengthWarning, error: minLengthError)
        maxLength = SeverityLevelsConfig(warning: maxLengthWarning, error: maxLengthError)
        self.excluded = Set(excluded)
    }

    public mutating func applyConfiguration(configuration: AnyObject) throws {
        guard let configDict = configuration as? [String: AnyObject] else {
            throw ConfigurationError.UnknownConfiguration
        }

        if let minLengthConfig = configDict["min_length"] {
            try minLength.applyConfiguration(minLengthConfig)
        }
        if let maxLengthConfig = configDict["max_length"] {
            try maxLength.applyConfiguration(maxLengthConfig)
        }
        if let excluded = [String].arrayOf(configDict["excluded"]) {
            self.excluded = Set(excluded)
        }
    }
}

public func == (lhs: NameConfig, rhs: NameConfig) -> Bool {
    return lhs.minLength == rhs.minLength &&
           lhs.maxLength == rhs.maxLength &&
           zip(lhs.excluded, rhs.excluded).reduce(true) { $0 && ($1.0 == $1.1) }
}

// MARK: - ConfigurationProviderRule extensions

public extension ConfigurationProviderRule where ConfigurationType == NameConfig {
    public func severity(forLength length: Int) -> ViolationSeverity? {
        if let minError = configuration.minLength.error where length < minError {
            return .Error
        } else if let maxError = configuration.maxLength.error where length > maxError {
            return .Error
        } else if length < configuration.minLength.warning ||
                  length > configuration.maxLength.warning {
            return .Warning
        }
        return nil
    }
}
