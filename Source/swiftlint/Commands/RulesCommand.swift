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
    let maxWidth: Int?

    init(header: String, values: [String], maxWidth: Int? = nil) {
        self.header = header
        self.values = values
        self.maxWidth = maxWidth
    }

    var width: Int {
        let maxValuesWidth = values.reduce(0) { max($0, $1.characters.count) }
        let maxContentWidth = max(header.characters.count, maxValuesWidth)
        return min(maxWidth ?? maxContentWidth, maxContentWidth)
    }
}

private func fence(strings: [String], separator: String) -> String {
    return separator + strings.joinWithSeparator(separator) + separator
}

// HELP! This function is extremely brittle.
// It only works with 3 columns, and only allows maxWidth to be set on the last column.
private func transformColumns(columns: [TextTableColumn]) -> [[String]] {
    return (0..<columns.first!.values.count).flatMap({ rowIndex -> [[String]] in
        var rowsOfValues = [[String]]()
        for column in columns {
            func setOrAppendToFirst(values: [String]) {
                let first = (rowsOfValues.first ?? []) + values
                if rowsOfValues.isEmpty {
                    rowsOfValues.append(first)
                } else {
                    rowsOfValues[0] = first
                }
            }
            func pad(string: String) -> String {
                return string.withPadding(column.width)
            }
            let value = column.values[rowIndex]
            guard let maxWidth = column.maxWidth where value.characters.count > maxWidth else {
                setOrAppendToFirst([pad(value)])
                continue
            }
            func split(string: String) -> (before: String, after: String) {
                let splitPoint = string.startIndex.advancedBy(string.substringToIndex(
                    string.startIndex.advancedBy(maxWidth)
                ).lastIndexOf(" ")! + 1)
                return (string.substringToIndex(splitPoint), string.substringFromIndex(splitPoint))
            }
            var (before, after) = split(value)
            setOrAppendToFirst([pad(before)])
            func append(string: String) {
                if string.isEmpty { return }
                rowsOfValues.append([
                    "".withPadding(columns[0].width),
                    "".withPadding(columns[1].width),
                    pad(string)
                ])
            }
            while after.characters.count > maxWidth {
                (before, after) = split(after)
                append(before)
            }
            append(after)
        }
        return rowsOfValues
    })
}

private struct TextTable {
    let columns: [TextTableColumn]

    func render() -> String {
        let joint = "+", verticalSeparator = "|", horizontalSeparator = "-"
        let separator = fence(columns.map({ column in
            Repeat(count: column.width + 2, repeatedValue: horizontalSeparator)
                .joinWithSeparator("")
        }), separator: joint)
        let header = fence(columns.map({ " \($0.header.withPadding($0.width)) " }),
            separator: verticalSeparator)
        let values = transformColumns(columns).flatMap({ values in
            if values.isEmpty { return nil }
            return fence(values.map({ " \($0) " }), separator: verticalSeparator)
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
            TextTableColumn(header: "description",
                values: sortedRules.map({ $0.1.description.description }), maxWidth: 100)
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
