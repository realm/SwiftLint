//
//  TextTable+SwiftLint.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 2/4/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import SwiftLintFramework
import SwiftyTextTable

extension TextTable {
    init(ruleList: RuleList, configuration: Configuration) {
        let columns = [
            TextTableColumn(header: "identifier"),
            TextTableColumn(header: "opt-in"),
            TextTableColumn(header: "correctable"),
            TextTableColumn(header: "enabled in your config"),
            TextTableColumn(header: "configuration")
        ]
        self.init(columns: columns)
        let sortedRules = ruleList.list.sort { $0.0 < $1.0 }
        for (ruleId, ruleType) in sortedRules {
            let rule = ruleType.init()
            addRow(ruleId,
                   (rule is OptInRule) ? "yes" : "no",
                   (rule is CorrectableRule) ? "yes" : "no",
                   configuration.rules.map({ $0.dynamicType.description.identifier })
                       .contains(ruleId) ? "yes" : "no",
                   (rule as? _ConfigProviderRule)?.configDescription ?? "N/A")
        }
    }
}
