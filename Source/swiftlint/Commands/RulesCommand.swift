//
//  RulesCommand.swift
//  SwiftLint
//
//  Created by Chris Eidhof on 20/05/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Commandant
import Result
import SwiftLintFramework

extension String {
    private func withPadding(count: Int, character: String = " ") -> String {
        let length = characters.count
        if length < count {
            return self +
                Repeat(count: count - length, repeatedValue: character).joinWithSeparator("")
        }
        return self
    }
}

private struct TextTableColumn {
    let header: String
    let values: [String]

    var width: Int {
        return max(header.characters.count, values.reduce(0) { max($0, $1.characters.count) })
    }
}

private struct TextTable {
    let columns: [TextTableColumn]

    func render() -> String {
        let widths = columns.map({ $0.width })
        let separator = "+" + widths.map({ width in
            return Repeat(count: width + 2, repeatedValue: "-").joinWithSeparator("")
        }).joinWithSeparator("+") + "+"
        let header = "|" + columns.map({
            " \($0.header.withPadding($0.width)) "
        }).joinWithSeparator("|") + "|"
        let result = separator + "\n\(header)\n" + separator + "\n"
        let values = (0..<columns.first!.values.count).map({ rowIndex in
            return "|" + columns.map({ column in
                return " \(column.values[rowIndex].withPadding(column.width)) "
            }).joinWithSeparator("|") + "|"
        }).joinWithSeparator("\n")
        return result + values + "\n" + separator
    }
}

private let violationMarker = "↓"

struct RulesCommand: CommandType {
    let verb = "rules"
    let function = "Display the list of rules and their identifiers"

    func run(options: RulesOptions) -> Result<(), CommandantError<()>> {
        if let ruleID = options.ruleID {
            guard let rule = masterRuleList.list[ruleID] else {
                return .Failure(.UsageError(description: "No rule with identifier: \(ruleID)"))
            }

            printRuleDescript(rule.description)
            return .Success()
        }

        let sortedRules = masterRuleList.list.sort { $0.0 < $1.0 }
        let table = TextTable(columns: [
            TextTableColumn(header: "identifier", values: sortedRules.map({ $0.0 })),
            TextTableColumn(header: "opt-in", values: sortedRules.map({ _, rule in
                return (rule.init() is OptInRule) ? "yes" : "no"
            })),
            TextTableColumn(header: "description", values: sortedRules.map({ _, rule in
                let maxLength = 100
                let description = rule.description.description
                if description.characters.count < maxLength {
                    return description
                }
                return description
                    .substringToIndex(description.startIndex.advancedBy(maxLength)) + "..."
            }))
        ])
        print(table.render())
        return .Success()
    }

    private func printRuleDescript(desc: RuleDescription) {
        print("\(desc.consoleDescription)")

        if !desc.triggeringExamples.isEmpty {
            func indent(string: String) -> String {
                return string.componentsSeparatedByString("\n")
                    .map { "    \($0)" }
                    .joinWithSeparator("\n")
            }
            print("\nTriggering Examples (violation is marked with '\(violationMarker)'):")
            for (index, example) in desc.triggeringExamples.enumerate() {
                print("\nExample #\(index + 1)\n\n\(indent(example))")
            }
        }
    }
}

struct RulesOptions: OptionsType {
    private let ruleID: String?

    private init(ruleID: String) {
        self.ruleID = ruleID.isEmpty ? nil : ruleID
    }

    // swiftlint:disable:next line_length
    static func evaluate(mode: CommandMode) -> Result<RulesOptions, CommandantError<CommandantError<()>>> {
        return self.init
            <*> mode <| Argument(defaultValue: "",
                usage: "the rule identifier to display description for")
    }
}
