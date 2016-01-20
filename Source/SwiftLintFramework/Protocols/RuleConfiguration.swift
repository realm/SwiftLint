//
//  RuleConfiguration.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/19/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public protocol RuleConfiguration {
    init()
    init?(config: AnyObject)
    func isEqualTo(ruleConfiguration: RuleConfiguration) -> Bool
}

public protocol ViolationLevelConfiguration: RuleConfiguration {
    var warning: RuleParameter<Int> { get set }
    var error: RuleParameter<Int> { get set }
}

extension ViolationLevelConfiguration {
    public init?(config: AnyObject) {
        self.init()
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
            return nil
        }
    }

    public func isEqualTo(config: ViolationLevelConfiguration) -> Bool {
        if let config = config as? Self {
            return warning == config.warning &&
                error == config.error
        }
        return false
    }
}
