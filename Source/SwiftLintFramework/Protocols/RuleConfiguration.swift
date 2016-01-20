//
//  RuleConfiguration.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/19/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public protocol RuleConfiguration {
    mutating func setConfiguration(config: AnyObject) throws
    func isEqualTo(ruleConfiguration: RuleConfiguration) -> Bool
}
