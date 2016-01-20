//
//  MinMaxLengthConfig.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/19/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct MinMaxLengthConfig: RuleConfiguration, Equatable {
    var min: SeverityLevelConfig
    var max: SeverityLevelConfig

    var minThreshold: Int {
        return Swift.max(min.warning.value, min.error.value)
    }

    var maxThreshold: Int {
        return Swift.min(max.warning.value, max.error.value)
    }

    init(minWarning: Int, minError: Int, maxWarning: Int, maxError: Int) {
        min = SeverityLevelConfig(warning: minWarning, error: minError)
        max = SeverityLevelConfig(warning: maxWarning, error: maxError)
    }

    public mutating func setConfiguration(config: AnyObject) throws {
        if let configDict = config as? [String: AnyObject] {
            if let minConfig = configDict["min_length"] {
                try min.setConfiguration(minConfig)
            }
            if let maxConfig = configDict["max_length"] {
                try max.setConfiguration(maxConfig)
            }
        } else {
            throw ConfigurationError.UnknownConfiguration
        }
    }

    public func isEqualTo(ruleConfiguration: RuleConfiguration) -> Bool {
        if let ruleConfig = ruleConfiguration as? MinMaxLengthConfig {
            return self == ruleConfig
        }
        return false
    }
}

public func == (lhs: MinMaxLengthConfig, rhs: MinMaxLengthConfig) -> Bool {
    return lhs.min == rhs.min &&
        lhs.max == rhs.max
}
