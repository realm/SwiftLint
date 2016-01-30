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
    private func withPadding(count: Int) -> String {
        let length = characters.count
        if length < count {
            return self +
                Repeat(count: count - length, repeatedValue: " ").joinWithSeparator("")
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

private func fence(strings: [String], separator: String) -> String {
    return separator + strings.joinWithSeparator(separator) + separator
}

private struct TextTable {
    let columns: [TextTableColumn]

    func render() -> String {
        let separator = fence(columns.map({ column in
            Repeat(count: column.width + 2, repeatedValue: "-").joinWithSeparator("")
        }), separator: "+")
        let header = fence(columns.map({ " \($0.header.withPadding($0.width)) " }),
            separator: "|")
        let values = (0..<columns.first!.values.count).map({ rowIndex in
            fence(columns.map({ column in
                " \(column.values[rowIndex].withPadding(column.width)) "
            }), separator: "|")
        }).joinWithSeparator("\n")
        return [separator, header, separator, values, separator].joinWithSeparator("\n")
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
            TextTableColumn(header: "opt-in",
                values: sortedRules.map({ ($0.1.init() is OptInRule) ? "yes" : "no" })),
            TextTableColumn(header: "correctable",
                values: sortedRules.map({ ($0.1.init() is CorrectableRule) ? "yes" : "no" })),
            TextTableColumn(header: "enabled in your config",
                values: sortedRules.map({
                    Configuration().rules.map({
                        $0.dynamicType.description.identifier
                    }).contains($0.0) ? "yes" : "no"
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
