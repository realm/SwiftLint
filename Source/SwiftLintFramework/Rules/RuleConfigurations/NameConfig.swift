//
//  NameConfig.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/19/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct NameConfig: RuleConfiguration, Equatable {
    var minLength: SeverityLevelConfig
    var maxLength: SeverityLevelConfig
    var excluded: [String]

    var minLengthThreshold: Int {
        return Swift.max(minLength.warning.value, minLength.error.value)
    }

    var maxLengthThreshold: Int {
        return Swift.min(maxLength.warning.value, maxLength.error.value)
    }

    init(minLengthWarning: Int,
         minLengthError: Int,
         maxLengthWarning: Int,
         maxLengthError: Int,
         excluded: [String] = []) {
        minLength = SeverityLevelConfig(warning: minLengthWarning, error: minLengthError)
        maxLength = SeverityLevelConfig(warning: maxLengthWarning, error: maxLengthError)
        self.excluded = excluded
    }

    public mutating func setConfiguration(config: AnyObject) throws {
        if let configDict = config as? [String: AnyObject] {
            if let minLengthConfig = configDict["min_length"] {
                try minLength.setConfiguration(minLengthConfig)
            }
            if let maxLengthConfig = configDict["max_length"] {
                try maxLength.setConfiguration(maxLengthConfig)
            }
            if let excluded = configDict["excluded"] as? [String] {
                    self.excluded = excluded
            }
        } else {
            throw ConfigurationError.UnknownConfiguration
        }
    }

    public func isEqualTo(ruleConfiguration: RuleConfiguration) -> Bool {
        if let ruleConfig = ruleConfiguration as? NameConfig {
            return self == ruleConfig
        }
        return false
    }

    public func violationSeverity(forLength length: Int) -> ViolationSeverity? {
        if length < minLength.error.value ||
           length > maxLength.error.value {
                return .Error
        } else if length < minLength.warning.value ||
                  length > maxLength.warning.value {
                return .Warning
        } else {
            return nil
        }
    }
}

public func == (lhs: NameConfig, rhs: NameConfig) -> Bool {
    return lhs.minLength == rhs.minLength &&
           lhs.maxLength == rhs.maxLength &&
           zip(lhs.excluded, rhs.excluded).reduce(true) { $0 && ($1.0 == $1.1) }
}
