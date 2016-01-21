//
//  NameConfig.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/19/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct NameConfig: RuleConfig, Equatable {
    var minLength: SeverityLevelsConfig
    var maxLength: SeverityLevelsConfig
    var excluded: Set<String>

    var minLengthThreshold: Int {
        return Swift.max(minLength.warning, minLength.error)
    }

    var maxLengthThreshold: Int {
        return Swift.min(maxLength.warning, maxLength.error)
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

    public mutating func setConfig(config: AnyObject) throws {
        if let configDict = config as? [String: AnyObject] {
            if let minLengthConfig = configDict["min_length"] {
                try minLength.setConfig(minLengthConfig)
            }
            if let maxLengthConfig = configDict["max_length"] {
                try maxLength.setConfig(maxLengthConfig)
            }
            if let excluded = [String].arrayOf(configDict["excluded"]) {
                    self.excluded = Set(excluded)
            }
        } else {
            throw ConfigurationError.UnknownConfiguration
        }
    }

    public func isEqualTo(ruleConfig: RuleConfig) -> Bool {
        if let ruleConfig = ruleConfig as? NameConfig {
            return self == ruleConfig
        }
        return false
    }
}

public func == (lhs: NameConfig, rhs: NameConfig) -> Bool {
    return lhs.minLength == rhs.minLength &&
           lhs.maxLength == rhs.maxLength &&
           zip(lhs.excluded, rhs.excluded).reduce(true) { $0 && ($1.0 == $1.1) }
}

// MARK: - ConfigProviderRule extensions

public extension ConfigProviderRule where ConfigType == NameConfig {
    public func severity(forLength length: Int) -> ViolationSeverity? {
        if length < config.minLength.error ||
           length > config.maxLength.error {
                return .Error
        } else if length < config.minLength.warning ||
                  length > config.maxLength.warning {
                return .Warning
        } else {
            return .None
        }
    }
}
