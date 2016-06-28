//
//  RuleList.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 12/28/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation

public struct RuleList {
    public static let defaultRuleTypes: [Rule.Type] = [
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
        LegacyCGGeometryFunctionsRule.self,
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
    ]

    public static let master = RuleList(rules: RuleList.defaultRuleTypes)

    public let list: [String: Rule.Type]

    public init(rules: [Rule.Type]) {
        var tmpList = [String: Rule.Type]()
        for rule in rules {
            tmpList[rule.description.identifier] = rule
        }
        list = tmpList
    }

    internal func configuredRulesWithDictionary(dictionary: [String: AnyObject]) -> [Rule] {
        var rules = [Rule]()
        for ruleType in list.values {
            let identifier = ruleType.description.identifier
            if let ruleConfiguration = dictionary[identifier] {
                do {
                    let configuredRule = try ruleType.init(configuration: ruleConfiguration)
                    rules.append(configuredRule)
                } catch {
                    queuedPrintError(
                        "Invalid configuration for '\(identifier)'. Falling back to default."
                    )
                    rules.append(ruleType.init())
                }
            } else {
                rules.append(ruleType.init())
            }
        }
        return rules
    }
}
