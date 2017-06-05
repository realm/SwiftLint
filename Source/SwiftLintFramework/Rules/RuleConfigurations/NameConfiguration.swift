//
//  NameConfiguration.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/19/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct NameConfiguration: RuleConfiguration, Equatable {
    public var consoleDescription: String {
        return "(min_length) \(minLength.shortConsoleDescription), " +
            "(max_length) \(maxLength.shortConsoleDescription), " +
            "excluded: \(excluded.sorted()), " +
            "allowed_symbols: \(allowedSymbols.sorted()), " +
            "validates_start_with_lowercase: \(validatesStartWithLowercase)"
    }

    var minLength: SeverityLevelsConfiguration
    var maxLength: SeverityLevelsConfiguration
    var excluded: Set<String>
    var allowedSymbols: Set<String>
    var validatesStartWithLowercase: Bool

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
                excluded: [String] = [],
                allowedSymbols: [String] = [],
                validatesStartWithLowercase: Bool = true) {
        minLength = SeverityLevelsConfiguration(warning: minLengthWarning, error: minLengthError)
        maxLength = SeverityLevelsConfiguration(warning: maxLengthWarning, error: maxLengthError)
        self.excluded = Set(excluded)
        self.allowedSymbols = Set(allowedSymbols)
        self.validatesStartWithLowercase = validatesStartWithLowercase
    }

    public mutating func apply(configuration: Any) throws {
        guard let configurationDict = configuration as? [String: Any] else {
            throw ConfigurationError.unknownConfiguration
        }

        if let minLengthConfiguration = configurationDict["min_length"] {
            try minLength.apply(configuration: minLengthConfiguration)
        }
        if let maxLengthConfiguration = configurationDict["max_length"] {
            try maxLength.apply(configuration: maxLengthConfiguration)
        }
        if let excluded = [String].array(of: configurationDict["excluded"]) {
            self.excluded = Set(excluded)
        }
        if let allowedSymbols = [String].array(of: configurationDict["allowed_symbols"]) {
            self.allowedSymbols = Set(allowedSymbols)
        }
        if let validatesStartWithLowercase = configurationDict["validates_start_lowercase"] as? Bool {
            self.validatesStartWithLowercase = validatesStartWithLowercase
        }
    }
}

public func == (lhs: NameConfiguration, rhs: NameConfiguration) -> Bool {
    return lhs.minLength == rhs.minLength &&
           lhs.maxLength == rhs.maxLength &&
           zip(lhs.excluded, rhs.excluded).reduce(true) { $0 && ($1.0 == $1.1) } &&
           zip(lhs.allowedSymbols, rhs.allowedSymbols).reduce(true) { $0 && ($1.0 == $1.1) } &&
           lhs.validatesStartWithLowercase == rhs.validatesStartWithLowercase
}

// MARK: - ConfigurationProviderRule extensions

public extension ConfigurationProviderRule where ConfigurationType == NameConfiguration {
    public func severity(forLength length: Int) -> ViolationSeverity? {
        if let minError = configuration.minLength.error, length < minError {
            return .error
        } else if let maxError = configuration.maxLength.error, length > maxError {
            return .error
        } else if length < configuration.minLength.warning ||
                  length > configuration.maxLength.warning {
            return .warning
        }
        return nil
    }
}
