//
//  RuleConfiguration.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/19/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation

public protocol RuleConfiguration {
    mutating func apply(configuration: Any) throws
    func isEqualTo(_ ruleConfiguration: RuleConfiguration) -> Bool
    var consoleDescription: String { get }
}

extension RuleConfiguration where Self: Equatable {
    public func isEqualTo(_ ruleConfiguration: RuleConfiguration) -> Bool {
        return self == ruleConfiguration as? Self
    }
}
