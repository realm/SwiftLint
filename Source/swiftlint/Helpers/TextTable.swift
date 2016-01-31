//
//  TextTable.swift
//  SwiftLint
//
//  Created by JP Simard on 1/31/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import SwiftLintFramework

extension String {
    private func withPadding(count: Int) -> String {
        let length = characters.count
        if length < count {
            return self +
                Repeat(count: count - length, repeatedValue: " ").joinWithSeparator("")
        }
        return self
    }
}

private func fence(strings: [String], separator: String) -> String {
    return separator + strings.joinWithSeparator(separator) + separator
}

struct TextTableColumn {
    let header: String
    let values: [String]

    var width: Int {
        return max(header.characters.count, values.reduce(0) { max($0, $1.characters.count) })
    }
}

struct TextTable {
    private let columns: [TextTableColumn]

    init(ruleList: RuleList) {
        let sortedRules = masterRuleList.list.sort { $0.0 < $1.0 }
        columns = [
            TextTableColumn(header: "identifier", values: sortedRules.map({ $0.0 })),
            TextTableColumn(header: "opt-in",
                values: sortedRules.map({ ($0.1.init() is OptInRule) ? "yes" : "no" })),
            TextTableColumn(header: "correctable",
                values: sortedRules.map({ ($0.1.init() is CorrectableRule) ? "yes" : "no" })),
            TextTableColumn(header: "enabled in your config",
                values: sortedRules.map({
                    Configuration().rules.map({
                        $0.dynamicType.description.identifier
                    }).contains($0.0) ? "yes" : "no"
                })),
            TextTableColumn(header: "configuration",
                values: sortedRules.map({ _, ruleType in
                    return (ruleType.init() as? _ConfigProviderRule)?.configDescription ?? "N/A"
                }))
        ]
    }

    func render() -> String {
        let separator = fence(columns.map({ column in
            Repeat(count: column.width + 2, repeatedValue: "-").joinWithSeparator("")
        }), separator: "+")
        let header = fence(columns.map({ " \($0.header.withPadding($0.width)) " }), separator: "|")
        let values = (0..<columns.first!.values.count).map({ rowIndex in
            fence(columns.map({ " \($0.values[rowIndex].withPadding($0.width)) " }), separator: "|")
        }).joinWithSeparator("\n")
        return [separator, header, separator, values, separator].joinWithSeparator("\n")
    }
}
