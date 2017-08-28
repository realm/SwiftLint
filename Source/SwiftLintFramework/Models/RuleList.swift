//
//  RuleList.swift
//  SwiftLint
//
//  Created by JP Simard on 5/31/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation

public enum RuleListError: Error {
    case duplicatedConfigurations(rule: Rule.Type)
}

public struct ConfiguredRule {
    public let rule: Rule
    public let isDefaultConfiguration: Bool
}

public struct RuleList {
    public let list: [String: Rule.Type]
    private let aliases: [String: String]

    public init(rules: Rule.Type...) {
        self.init(rules: rules)
    }

    public init(rules: [Rule.Type]) {
        var tmpList = [String: Rule.Type]()
        var tmpAliases = [String: String]()

        for rule in rules {
            let identifier = rule.description.identifier
            tmpList[identifier] = rule
            for alias in rule.description.deprecatedAliases {
                tmpAliases[alias] = identifier
            }
            tmpAliases[identifier] = identifier
        }
        list = tmpList
        aliases = tmpAliases
    }

    internal func configuredRules(with dictionary: [String: Any]) throws -> [ConfiguredRule] {
        var rules = [String: ConfiguredRule]()

        for (key, configuration) in dictionary {
            guard let identifier = identifier(for: key), let ruleType = list[identifier] else {
                continue
            }
            guard rules[identifier] == nil else {
                throw RuleListError.duplicatedConfigurations(rule: ruleType)
            }
            do {
                let configuredRule = try ruleType.init(configuration: configuration)
                rules[identifier] = ConfiguredRule(rule: configuredRule, isDefaultConfiguration: false)
            } catch {
                queuedPrintError("Invalid configuration for '\(identifier)'. Falling back to default.")
                rules[identifier] = ConfiguredRule(rule: ruleType.init(), isDefaultConfiguration: true)
            }
        }

        for (identifier, ruleType) in list where rules[identifier] == nil {
            rules[identifier] = ConfiguredRule(rule: ruleType.init(), isDefaultConfiguration: true)
        }

        return Array(rules.values)
    }

    internal func identifier(for alias: String) -> String? {
        return aliases[alias]
    }

    internal func allValidIdentifiers() -> [String] {
        return list.flatMap { (_, rule) -> [String] in
            rule.description.allIdentifiers
        }
    }
}
