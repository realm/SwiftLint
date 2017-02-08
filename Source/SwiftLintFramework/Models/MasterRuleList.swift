//
//  MasterRuleList.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 12/28/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation

public enum RuleListError: Error {
    case duplicatedConfigurations(rule: Rule.Type)
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

    internal func configuredRules(with dictionary: [String: Any]) throws -> [Rule] {
        var rules = [String: Rule]()

        for (key, configuration) in dictionary {
            guard let identifier = identifier(for: key), let ruleType = list[identifier] else {
                continue
            }
            guard rules[identifier] == nil else {
                throw RuleListError.duplicatedConfigurations(rule: ruleType)
            }
            do {
                let configuredRule = try ruleType.init(configuration: configuration)
                rules[identifier] = configuredRule
            } catch {
                queuedPrintError("Invalid configuration for '\(identifier)'. Falling back to default.")
                rules[identifier] = ruleType.init()
            }
        }

        for (identifier, ruleType) in list where rules[identifier] == nil {
            rules[identifier] = ruleType.init()
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

public let masterRuleList = RuleList(rules:
    AttributesRule.self,
    ClassDelegateProtocolRule.self,
    ClosingBraceRule.self,
    ClosureEndIndentationRule.self,
    ClosureParameterPositionRule.self,
    ClosureSpacingRule.self,
    ColonRule.self,
    CommaRule.self,
    CompilerProtocolInitRule.self,
    ConditionalReturnsOnNewline.self,
    ControlStatementRule.self,
    CustomRules.self,
    CyclomaticComplexityRule.self,
    DiscardedNotificationCenterObserverRule.self,
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
    ForWhereRule.self,
    FunctionBodyLengthRule.self,
    FunctionParameterCountRule.self,
    GenericTypeNameRule.self,
    IdentifierNameRule.self,
    ImplicitGetterRule.self,
    LargeTupleRule.self,
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
    NotificationCenterDetachmentRule.self,
    NumberSeparatorRule.self,
    ObjectLiteralRule.self,
    OpeningBraceRule.self,
    OperatorFunctionWhitespaceRule.self,
    OperatorUsageWhitespaceRule.self,
    OverriddenSuperCallRule.self,
    PrivateOutletRule.self,
    PrivateUnitTestRule.self,
    ProhibitedSuperRule.self,
    RedundantDiscardableLetRule.self,
    RedundantNilCoalescingRule.self,
    RedundantOptionalInitializationRule.self,
    RedundantStringEnumValueRule.self,
    RedundantVoidReturnRule.self,
    ReturnArrowWhitespaceRule.self,
    ShorthandOperatorRule.self,
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
    UnusedOptionalBindingRule.self,
    ValidDocsRule.self,
    ValidIBInspectableRule.self,
    VerticalParameterAlignmentRule.self,
    VerticalWhitespaceRule.self,
    VoidReturnRule.self,
    WeakDelegateRule.self
)
