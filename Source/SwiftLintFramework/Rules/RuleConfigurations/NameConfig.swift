//
//  NameConfig.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/19/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct NameConfig: RuleConfiguration, Equatable {
    var min: SeverityLevelConfig
    var max: SeverityLevelConfig
    var excluded: [String]

    var minThreshold: Int {
        return Swift.max(min.warning.value, min.error.value)
    }

    var maxThreshold: Int {
        return Swift.min(max.warning.value, max.error.value)
    }

    init(minWarning: Int, minError: Int, maxWarning: Int, maxError: Int, excluded: [String] = []) {
        min = SeverityLevelConfig(warning: minWarning, error: minError)
        max = SeverityLevelConfig(warning: maxWarning, error: maxError)
        self.excluded = excluded
    }

    public mutating func setConfiguration(config: AnyObject) throws {
        if let configDict = config as? [String: AnyObject] {
            if let minConfig = configDict["min_length"] {
                try min.setConfiguration(minConfig)
            }
            if let maxConfig = configDict["max_length"] {
                try max.setConfiguration(maxConfig)
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
}

public func == (lhs: NameConfig, rhs: NameConfig) -> Bool {
    return lhs.min == rhs.min &&
           lhs.max == rhs.max &&
           zip(lhs.excluded, rhs.excluded).reduce(true) { $0 && ($1.0 == $1.1) }
}
