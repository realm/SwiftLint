//
//  RuleMinMaxConfig.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/19/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct RuleMinMaxConfig: RuleConfiguration, Equatable {
    var min: RuleLevelsConfig
    var max: RuleLevelsConfig

    init(minWarning: Int, minError: Int, maxWarning: Int, maxError: Int) {
        min = RuleLevelsConfig(warning: minWarning, error: minError)
        max = RuleLevelsConfig(warning: maxWarning, error: maxError)
    }

    public mutating func setConfiguration(config: AnyObject) throws {
        if let configDict = config as? [String: AnyObject] {
            if let minConfig = configDict["min"] {
                try min.setConfiguration(minConfig)
            }
            if let maxConfig = configDict["max"] {
                try max.setConfiguration(maxConfig)
            }
        } else {
            throw ConfigurationError.UnknownConfiguration
        }
    }

    public func isEqualTo(ruleConfiguration: RuleConfiguration) -> Bool {
        if let ruleConfig = ruleConfiguration as? RuleMinMaxConfig {
            return self == ruleConfig
        }
        return false
    }
}

public func == (lhs: RuleMinMaxConfig, rhs: RuleMinMaxConfig) -> Bool {
    return lhs.min == rhs.min &&
        lhs.max == rhs.max
}
