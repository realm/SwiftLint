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

        let configuration = Configuration(commandLinePath: options.configurationFile)
        print(TextTable(ruleList: masterRuleList, configuration: configuration).render())
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
    private let configurationFile: String

    static func create(configurationFile: String) -> (ruleID: String) -> RulesOptions {
        return { ruleID in
            self.init(ruleID: (ruleID.isEmpty ? nil : ruleID), configurationFile: configurationFile)
        }
    }

    // swiftlint:disable:next line_length
    static func evaluate(mode: CommandMode) -> Result<RulesOptions, CommandantError<CommandantError<()>>> {
        return create
            <*> mode <| Option(key: "config",
                defaultValue: Configuration.fileName,
                usage: "the path to SwiftLint's configuration file")
            <*> mode <| Argument(defaultValue: "",
                usage: "the rule identifier to display description for")
    }
}
