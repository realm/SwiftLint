//
//  RuleConfiguration.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/19/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public enum ConfigurationError: ErrorType {
    case UnknownConfiguration
}

public protocol RuleConfiguration {
    mutating func setConfiguration(config: AnyObject) throws
    func isEqualTo(ruleConfiguration: RuleConfiguration) -> Bool
}

public struct VLConfig: RuleConfiguration, Equatable {
    var warning: RuleParameter<Int>
    var error: RuleParameter<Int>

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
        if let config = ruleConfiguration as? VLConfig {
            self == config
        }
        return false
    }
}

public func == (lhs: VLConfig, rhs: VLConfig) -> Bool {
    return lhs.warning == rhs.warning &&
           lhs.error == rhs.error
}

public struct MinMaxConfiguration: RuleConfiguration, Equatable {
    var min: VLConfig
    var max: VLConfig

    init(minWarning: Int, minError: Int, maxWarning: Int, maxError: Int) {
        min = VLConfig(warning: minWarning, error: minError)
        max = VLConfig(warning: maxWarning, error: maxError)
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
        if let ruleConfig = ruleConfiguration as? MinMaxConfiguration {
            return self == ruleConfig
        }
        return false
    }
}

public func == (lhs: MinMaxConfiguration, rhs: MinMaxConfiguration) -> Bool {
    return lhs.min == rhs.min &&
        lhs.max == rhs.max
}
