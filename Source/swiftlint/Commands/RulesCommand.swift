//
//  RulesCommand.swift
//  SwiftLint
//
//  Created by Chris Eidhof on 20/05/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Commandant
import Result
import SwiftLintFramework
import SwiftyTextTable

private func print(ruleDescription desc: RuleDescription) {
    print("\(desc.consoleDescription)")

    if !desc.triggeringExamples.isEmpty {
        func indent(_ string: String) -> String {
            return string.components(separatedBy: "\n")
                .map { "    \($0)" }
                .joined(separator: "\n")
        }
        print("\nTriggering Examples (violation is marked with '↓'):")
        for (index, example) in desc.triggeringExamples.enumerated() {
            print("\nExample #\(index + 1)\n\n\(indent(example))")
        }
    }
}

struct RulesCommand: CommandProtocol {
    let verb = "rules"
    let function = "Display the list of rules and their identifiers"

    func run(_ options: RulesOptions) -> Result<(), CommandantError<()>> {
        if let ruleID = options.ruleID {
            guard let rule = masterRuleList.list[ruleID] else {
                return .failure(.usageError(description: "No rule with identifier: \(ruleID)"))
            }

            print(ruleDescription: rule.description)
            return .success()
        }

        let configuration = Configuration(commandLinePath: options.configurationFile)
        let rules = ruleList(for: options, configuration: configuration)

        print(TextTable(ruleList: rules, configuration: configuration).render())
        return .success()
    }

    private func ruleList(for options: RulesOptions, configuration: Configuration) -> RuleList {
        guard options.filterEnabled else {
            return masterRuleList
        }

        let filtered: [Rule.Type] = masterRuleList.list.flatMap { ruleID, ruleType in
            let configuredRule = configuration.rules.first { rule in
                return type(of: rule).description.identifier == ruleID
            }

            guard configuredRule != nil else {
                return nil
            }

            return ruleType
        }

        return RuleList(rules: filtered)
    }
}

struct RulesOptions: OptionsProtocol {
    fileprivate let ruleID: String?
    fileprivate let configurationFile: String
    fileprivate let filterEnabled: Bool

    static func create(_ configurationFile: String) -> (_ ruleID: String) -> (_ filterEnabled: Bool) -> RulesOptions {
        return { ruleID in { filterEnabled in
            // swiftlint:disable:next line_length
            self.init(ruleID: (ruleID.isEmpty ? nil : ruleID), configurationFile: configurationFile, filterEnabled: filterEnabled)
        }}
    }

    static func evaluate(_ mode: CommandMode) -> Result<RulesOptions, CommandantError<CommandantError<()>>> {
        return create
            <*> mode <| configOption
            <*> mode <| Argument(defaultValue: "",
                                 usage: "the rule identifier to display description for")
            <*> mode <| Switch(flag: "e",
                               key: "enabled",
                               usage: "only display enabled rules")
    }
}

// MARK: - SwiftyTextTable

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
        let sortedRules = ruleList.list.sorted { $0.0 < $1.0 }
        for (ruleID, ruleType) in sortedRules {
            let rule = ruleType.init()
            let configuredRule = configuration.rules.first { rule in
                return type(of: rule).description.identifier == ruleID
            }
            addRow(values: [
                ruleID,
                (rule is OptInRule) ? "yes" : "no",
                (rule is CorrectableRule) ? "yes" : "no",
                configuredRule != nil ? "yes" : "no",
                (configuredRule ?? rule).configurationDescription
            ])
        }
    }
}
