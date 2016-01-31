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
                return .Failure(CommandantError<()>
                    .UsageError(description: "No rule with identifier: \(ruleID)"))
            }

            printRuleDescript(rule.description)
            return .Success()
        }

        print(masterRuleList.list.keys.joinWithSeparator("\n"))
        return .Success()
    }

    private func printRuleDescript(desc: RuleDescription) {
        print("\(desc.consoleDescription)")

        func indent(string: String) -> String {
            return string.componentsSeparatedByString("\n")
                .map { "    \($0)" }
                .joinWithSeparator("\n")
        }

        if !desc.triggeringExamples.isEmpty {
            print("\nTriggering Examples (violation is marked with '\(violationMarker)'):")
            for idx in 0..<desc.triggeringExamples.count {
                print("\nExample #\(idx + 1)\n")
                print("\(indent(desc.triggeringExamples[idx]))")
            }
        }
    }
}

struct RulesOptions: OptionsType {

    private let ruleID: String?

    private init(ruleID: String) {
        self.ruleID = ruleID == "" ? nil : ruleID
    }

    // swiftlint:disable:next line_length
    static func evaluate(mode: CommandMode) -> Result<RulesOptions, CommandantError<CommandantError<()>>> {
        return self.init
            <*> mode <| Argument(defaultValue: "",
                usage: "the rule identifier to display description for")
    }

}
