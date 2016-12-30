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

    internal func configuredRules(with dictionary: [String: Any]) -> [Rule] {
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

public let masterRuleList = RuleList(rules:
    AttributesRule.self,
    ClassDelegateProtocolRule.self,
    ClosingBraceRule.self,
    ClosureEndIndentationRule.self,
    ClosureParameterPositionRule.self,
    ClosureSpacingRule.self,
    ColonRule.self,
    CommaRule.self,
    ConditionalReturnsOnNewline.self,
    ControlStatementRule.self,
    CustomRules.self,
    CyclomaticComplexityRule.self,
    DynamicInlineRule.self,
    EmptyCountRule.self,
    EmptyParametersRule.self,
    EmptyParenthesesWithTrailingClosureRule.self,
    ExplicitInitRule.self,
    FileHeaderRule.self,
    FileLengthRule.self,
    FirstWhereRule.self,
    ForceCastRule.self,
    ForceTryRule.self,
    ForceUnwrappingRule.self,
    FunctionBodyLengthRule.self,
    FunctionParameterCountRule.self,
    ImplicitGetterRule.self,
    InferredSortingRule.self,
    LeadingWhitespaceRule.self,
    LegacyCGGeometryFunctionsRule.self,
    LegacyConstantRule.self,
    LegacyConstructorRule.self,
    LegacyNSGeometryFunctionsRule.self,
    LineLengthRule.self,
    MarkRule.self,
    MissingDocsRule.self,
    NestingRule.self,
    NimbleOperatorRule.self,
    NumberSeparatorRule.self,
    OpeningBraceRule.self,
    OperatorFunctionWhitespaceRule.self,
    OperatorUsageWhitespaceRule.self,
    OverriddenSuperCallRule.self,
    PrivateOutletRule.self,
    PrivateUnitTestRule.self,
    ProhibitedSuperRule.self,
    RedundantNilCoalescingRule.self,
    RedundantOptionalInitializationRule.self,
    RedundantStringEnumValueRule.self,
    RedundantVoidReturnRule.self,
    ReturnArrowWhitespaceRule.self,
    SortedImportsRule.self,
    StatementPositionRule.self,
    SwitchCaseOnNewlineRule.self,
    SyntacticSugarRule.self,
    TodoRule.self,
    TrailingCommaRule.self,
    TrailingNewlineRule.self,
    TrailingSemicolonRule.self,
    TrailingWhitespaceRule.self,
    TypeBodyLengthRule.self,
    TypeNameRule.self,
    UnusedClosureParameterRule.self,
    UnusedEnumeratedRule.self,
    ValidDocsRule.self,
    ValidIBInspectableRule.self,
    VariableNameRule.self,
    VerticalParameterAlignmentRule.self,
    VerticalWhitespaceRule.self,
    VoidReturnRule.self,
    WeakDelegateRule.self
)
