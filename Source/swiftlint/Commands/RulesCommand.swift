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
import SwiftyTextTable

private let violationMarker = "↓"

struct RulesCommand: CommandType {
    let verb = "rules"
    let function = "Display the list of rules and their identifiers"

    func run(options: RulesOptions) -> Result<(), CommandantError<()>> {
        let ruleList = RuleList(pluginPaths: options.pluginPaths)
        let configuration = Configuration(commandLinePath: options.configurationFile,
                                          ruleList: ruleList)
        if let ruleID = options.ruleID {
            guard let rule = configuration.ruleList.list[ruleID] else {
                return .Failure(.UsageError(description: "No rule with identifier: \(ruleID)"))
            }

            printRuleDescript(rule.description)
            return .Success()
        }

        print(TextTable(configuration: configuration).render())
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

struct RulesOptions: OptionsType, PluginsOptionsType {
    let ruleID: String?
    let configurationFile: String
    let plugins: String?

    // swiftlint:disable:next line_length
    static func create(configurationFile: String) -> (plugins: String) -> (ruleID: String) -> RulesOptions {
        return { plugins in { ruleID in
            self.init(ruleID: (ruleID.isEmpty ? nil : ruleID), configurationFile: configurationFile,
                      plugins: (plugins.isEmpty ? nil : plugins))
        }}
    }

    // swiftlint:disable:next line_length
    static func evaluate(mode: CommandMode) -> Result<RulesOptions, CommandantError<CommandantError<()>>> {
        return create
            <*> mode <| configOption
            <*> mode <| pluginOption
            <*> mode <| Argument(defaultValue: "",
                                 usage: "the rule identifier to display description for")
    }
}

// MARK: - SwiftyTextTable

extension TextTable {
    init(configuration: Configuration) {
        let columns = [
            TextTableColumn(header: "identifier"),
            TextTableColumn(header: "opt-in"),
            TextTableColumn(header: "correctable"),
            TextTableColumn(header: "enabled in your config"),
            TextTableColumn(header: "configuration")
        ]
        self.init(columns: columns)
        let sortedRules = configuration.ruleList.list.sort { $0.0 < $1.0 }
        for (ruleID, ruleType) in sortedRules {
            let rule = ruleType.init()
            let configuredRule: Rule? = {
                for rule in configuration.rules
                    where rule.dynamicType.description.identifier == ruleID {
                        return rule
                }
                return nil
            }()
            addRow([
                ruleID,
                (rule is OptInRule) ? "yes" : "no",
                (rule is CorrectableRule) ? "yes" : "no",
                configuredRule != nil ? "yes" : "no",
                (configuredRule ?? rule).configurationDescription
            ])
        }
    }
}
