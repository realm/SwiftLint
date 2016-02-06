//
//  MasterRuleList.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 12/28/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation

public struct RuleList {
    public let list: [String: Rule.Type]
    public init(rules: Rule.Type...) {
        var tmpList = [String: Rule.Type]()
        for rule in rules {
            tmpList[rule.description.identifier] = rule
        }
        list = tmpList
    }

    internal func configuredRulesWithDictionary(dictionary: [String: AnyObject]) -> [Rule] {
        var rules = [Rule]()
        for rule in list.values {
            let identifier = rule.description.identifier
            if let ConfigurableRuleType = rule as? ConfigurableRule.Type,
                ruleConfig = dictionary[identifier] {
                do {
                    let configuredRule = try ConfigurableRuleType.init(config: ruleConfig)
                    rules.append(configuredRule)
                } catch {
                    queuedPrintError("Invalid config for '\(identifier)'. Falling back to default.")
                    rules.append(rule.init())
                }
            } else {
                rules.append(rule.init())
            }
        }
        return rules
    }
}

public let masterRuleList = RuleList(rules:
    ClosingBraceRule.self,
    ColonRule.self,
    CommaRule.self,
    ConditionalBindingCascadeRule.self,
    ControlStatementRule.self,
    CustomRules.self,
    CyclomaticComplexityRule.self,
    EmptyCountRule.self,
    FileLengthRule.self,
    ForceCastRule.self,
    ForceTryRule.self,
    ForceUnwrappingRule.self,
    FunctionBodyLengthRule.self,
    FunctionParameterCountRule.self,
    LeadingWhitespaceRule.self,
    LegacyConstantRule.self,
    LegacyConstructorRule.self,
    LineLengthRule.self,
    MissingDocsRule.self,
    NestingRule.self,
    OpeningBraceRule.self,
    OperatorFunctionWhitespaceRule.self,
    ReturnArrowWhitespaceRule.self,
    StatementPositionRule.self,
    TodoRule.self,
    TrailingNewlineRule.self,
    TrailingSemicolonRule.self,
    TrailingWhitespaceRule.self,
    TypeBodyLengthRule.self,
    TypeNameRule.self,
    ValidDocsRule.self,
    VariableNameRule.self
)
