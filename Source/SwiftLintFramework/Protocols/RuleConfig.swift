//
//  RuleConfig.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/19/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public protocol RuleConfig {
    mutating func setConfig(config: AnyObject) throws
    func isEqualTo(ruleConfig: RuleConfig) -> Bool
}

extension RuleConfig where Self: Equatable {
    public func isEqualTo(ruleConfig: RuleConfig) -> Bool {
        if let ruleConfig = ruleConfig as? Self {
            return self == ruleConfig
        }
        return false
    }
}
