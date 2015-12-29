//
//  MasterRuleList.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 12/28/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation

struct RuleList {
    let list: [String: Rule]
    init(rules: Rule...) {
        var tmpList = [String: Rule]()
        for rule in rules {
            tmpList[rule.dynamicType.description.identifier] = rule
        }
        list = tmpList
    }
}

let masterRuleList = RuleList( rules: ClosingBraceRule(),
                                      ColonRule(),
                                      CommaRule(),
                                      ControlStatementRule(),
                                      FileLengthRule(),
                                      ForceCastRule(),
                                      FunctionBodyLengthRule(),
                                      LeadingWhitespaceRule(),
                                      LegacyConstructorRule(),
                                      LineLengthRule(),
                                      NestingRule(),
                                      OpeningBraceRule(),
                                      OperatorFunctionWhitespaceRule(),
                                      ReturnArrowWhitespaceRule(),
                                      StatementPositionRule(),
                                      TodoRule(),
                                      TrailingNewlineRule(),
                                      TrailingSemicolonRule(),
                                      TrailingWhitespaceRule(),
                                      TypeBodyLengthRule(),
                                      TypeNameRule(),
                                      ValidDocsRule(),
                                      VariableNameMaxLengthRule(),
                                      VariableNameMinLengthRule(),
                                      VariableNameRule())
