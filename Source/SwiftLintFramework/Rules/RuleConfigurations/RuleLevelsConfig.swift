//
//  RuleLevelsConfig.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/19/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct RuleLevelsConfig: RuleConfiguration, Equatable {
    var warning: RuleParameter<Int>
    var error: RuleParameter<Int>

    var params: [RuleParameter<Int>] {
        return [error, warning]
    }

    public init(warning warningLevel: Int, error errorLevel: Int) {
        warning = RuleParameter(severity: .Warning, value: warningLevel)
        error = RuleParameter(severity: .Error, value: errorLevel)
    }

    mutating public func setConfiguration(config: AnyObject) throws {
        if let config = [Int].arrayOf(config) where !config.isEmpty {
            warning = RuleParameter(severity: .Warning, value: config[0])
            if config.count > 1 {
                error = RuleParameter(severity: .Error, value: config[1])
            }
        } else if let config = config as? [String: AnyObject] {
            if let warningNumber = config["warning"] as? Int {
                warning = RuleParameter(severity: .Warning, value: warningNumber)
            }
            if let errorNumber = config["error"] as? Int {
                error = RuleParameter(severity: .Error, value: errorNumber)
            }
        } else {
            throw ConfigurationError.UnknownConfiguration
        }
    }

    public func isEqualTo(ruleConfiguration: RuleConfiguration) -> Bool {
        if let config = ruleConfiguration as? RuleLevelsConfig {
            return self == config
        }
        return false
    }
}

public func == (lhs: RuleLevelsConfig, rhs: RuleLevelsConfig) -> Bool {
    return lhs.warning == rhs.warning && lhs.error == rhs.error
}
