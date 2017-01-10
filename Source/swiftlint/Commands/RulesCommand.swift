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
        print(TextTable(ruleList: masterRuleList, configuration: configuration).render())
        return .success()
    }
}

struct RulesOptions: OptionsProtocol {
    fileprivate let ruleID: String?
    fileprivate let configurationFile: String

    static func create(_ configurationFile: String) -> (_ ruleID: String) -> RulesOptions {
        return { ruleID in
            self.init(ruleID: (ruleID.isEmpty ? nil : ruleID), configurationFile: configurationFile)
        }
    }

    // swiftlint:disable:next line_length
    static func evaluate(_ mode: CommandMode) -> Result<RulesOptions, CommandantError<CommandantError<()>>> {
        return create
            <*> mode <| configOption
            <*> mode <| Argument(defaultValue: "",
                                 usage: "the rule identifier to display description for")
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
