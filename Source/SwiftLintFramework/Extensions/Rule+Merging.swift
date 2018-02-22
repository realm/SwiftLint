//
//  Rule+Merging.swift
//  SwiftLint
//
//  Created by Christopher Gretzki on 22.02.18.
//  Copyright © 2018 Realm. All rights reserved.
//

import Foundation

public extension Rule {
    func overrideConfiguration(withRule secondRule: Rule) -> Rule {
        guard let secondRule = secondRule as? Self else {
            queuedFatalError("Call overrideConfiguration only on rule's of same type")
        }
        var parentRuleConfiguration = getConfiguration(of: self)
        let nestedRuleConfiguration = getConfiguration(of: secondRule)
        // check if rule's configuration exists
        guard parentRuleConfiguration != nil, nestedRuleConfiguration != nil else {
            // can't find any configuration - return nested rule
            return secondRule
        }
        // override rule's configuration with nested rule's configuration
        do {
            try parentRuleConfiguration?.apply(configuration: nestedRuleConfiguration!)
        } catch {
            // RuleConfiguration is not ready to be configured via RuleConfiguration of own type as parameter, yet
            // skip error to stay backward compatible
            print("""
                RuleConfiguration \(parentRuleConfiguration!) is not ready to be configured
                via apply() with parameter of own type
                """)
        }
        return self
    }

    /// This method is an ugly hack to check if rule: Rule also conforms to ConfigurationProviderRule
    /// This workaround checks for a configuration property
    ///
    /// - Parameter rule: Anything conforming to Rule
    /// - Returns: RuleConfiguration if given rule conforms to ConfigurationProviderRule
    func getConfiguration(of rule: Rule) -> RuleConfiguration? {
        var ruleConfig: RuleConfiguration?
        let mirror = Mirror(reflecting: rule)
        if let b = AnyBidirectionalCollection(mirror.children) {
            ruleConfig = b.first(where: { (label: String?, _: Any) -> Bool in
                label == "configuration"
            }).map({ $0.value }) as? RuleConfiguration
        }
        return ruleConfig
    }
}
