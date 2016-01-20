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
}

public let masterRuleList = RuleList( rules: ClosingBraceRule.self,
                                      ColonRule.self,
                                      CommaRule.self,
                                      ConditionalBindingCascadeRule.self,
                                      ControlStatementRule.self,
                                      EmptyCountRule.self,
                                      FileLengthRule.self,
                                      ForceCastRule.self,
                                      ForceTryRule.self,
                                      FunctionBodyLengthRule.self,
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
                                      VariableNameRule.self)
