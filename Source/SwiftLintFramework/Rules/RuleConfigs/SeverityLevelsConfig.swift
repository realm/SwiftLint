//
//  SeverityLevelsConfig.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/19/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct SeverityLevelsConfig: RuleConfiguration, Equatable {
    var warning: Int
    var error: Int

    var params: [RuleParameter<Int>] {
        return [RuleParameter(severity: .Error, value: error),
                RuleParameter(severity: .Warning, value: warning)]
    }

    mutating public func setConfiguration(config: AnyObject) throws {
        if let config = [Int].arrayOf(config) where !config.isEmpty {
            warning = config[0]
            if config.count > 1 {
                error = config[1]
            }
        } else if let config = config as? [String: AnyObject] {
            if let warningNumber = config["warning"] as? Int {
                warning = warningNumber
            }
            if let errorNumber = config["error"] as? Int {
                error = errorNumber
            }
        } else {
            throw ConfigurationError.UnknownConfiguration
        }
    }

    public func isEqualTo(ruleConfiguration: RuleConfiguration) -> Bool {
        if let config = ruleConfiguration as? SeverityLevelsConfig {
            return self == config
        }
        return false
    }
}

public func == (lhs: SeverityLevelsConfig, rhs: SeverityLevelsConfig) -> Bool {
    return lhs.warning == rhs.warning && lhs.error == rhs.error
}
