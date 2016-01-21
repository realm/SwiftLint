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
