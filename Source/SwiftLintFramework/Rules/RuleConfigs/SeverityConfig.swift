//
//  SeverityConfig.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/20/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public struct SeverityConfig: RuleConfiguration, Equatable {
    var severity: ViolationSeverity

    public init(severity: ViolationSeverity) {
        self.severity = severity
    }

    public mutating func setConfiguration(config: AnyObject) throws {
        let value = config as? String ?? (config as? [String: AnyObject])?["severity"] as? String
        if let value = value, let severity = ViolationSeverity(rawValue: value.capitalizedString) {
            self.severity = severity
        } else {
            throw ConfigurationError.UnknownConfiguration
        }
    }

    public func isEqualTo(ruleConfiguration: RuleConfiguration) -> Bool {
        if let config = ruleConfiguration as? SeverityConfig {
            return self == config
        }
        return false
    }
}

public func == (lhs: SeverityConfig, rhs: SeverityConfig) -> Bool {
    return lhs.severity == rhs.severity
}
