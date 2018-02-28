//
//  Rule+Merging.swift
//  SwiftLint
//
//  Created by Christopher Gretzki on 02/22/18.
//  Copyright © 2018 Realm. All rights reserved.
//

import Foundation
import Reflection

public extension Rule {
    mutating func overrideConfiguration(withRule secondRule: Rule) -> Rule {
        guard let secondRule = secondRule as? Self else {
            queuedFatalError("Call overrideConfiguration only on rule's of same type")
        }
        let parentRuleConfiguration = getConfiguration()
        let nestedRuleConfiguration = secondRule.getConfiguration()
        // check if rule's configuration exists
        if var mergedRuleConfig = parentRuleConfiguration, nestedRuleConfiguration != nil {
            // override rule's configuration with nested rule's configuration
            do {
                try mergedRuleConfig.apply(configuration: nestedRuleConfiguration!)
                try set(mergedRuleConfig, key: "configuration", for: &self)
            } catch {
                // RuleConfiguration is not ready to be configured via RuleConfiguration of own type as parameter, yet
                // skip error to stay backward compatible
                print("""
                    RuleConfiguration \(parentRuleConfiguration!) is not ready to be configured
                    via apply() with parameter of own type
                    """)
            }
            return self
        } else {
            // fallback to previous behaviour w/o merging rule's configuration
            return secondRule
        }
    }

    /// This method is a workaround to retrieve the `configuration` property of a ConfigurationProviderRule
    /// Since Swift4 does not allow for checking conformance with protocols using associated types
    /// this workaround uses reflection
    ///
    /// - Parameter rule: Anything conforming to Rule
    /// - Returns: RuleConfiguration if given rule conforms to ConfigurationProviderRule
    func getConfiguration() -> RuleConfiguration? {
        let ruleConfig: RuleConfiguration? = try? get("configuration", from: self)
        return ruleConfig
    }
}
