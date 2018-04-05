//
//  RulesCommand.swift
//  SwiftLint
//
//  Created by Chris Eidhof on 20/05/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Commandant
#if os(Linux)
import Glibc
#else
import Darwin
#endif
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
            return .success(())
        }

        if options.onlyDisabledRules && options.onlyEnabledRules {
            return .failure(.usageError(description: "You can't use --disabled and --enabled at the same time."))
        }

        let configuration = Configuration(options: options)
        let rules = ruleList(for: options, configuration: configuration)

        print(TextTable(ruleList: rules, configuration: configuration).render())
        return .success(())
    }

    private func ruleList(for options: RulesOptions, configuration: Configuration) -> RuleList {
        guard options.onlyEnabledRules || options.onlyDisabledRules else {
            return masterRuleList
        }

        let filtered: [Rule.Type] = masterRuleList.list.compactMap { ruleID, ruleType in
            let configuredRule = configuration.rules.first { rule in
                return type(of: rule).description.identifier == ruleID
            }

            if options.onlyEnabledRules && configuredRule == nil {
                return nil
            } else if options.onlyDisabledRules && configuredRule != nil {
                return nil
            }

            return ruleType
        }

        return RuleList(rules: filtered)
    }
}

struct RulesOptions: OptionsProtocol {
    fileprivate let ruleID: String?
    let configurationFile: String
    fileprivate let onlyEnabledRules: Bool
    fileprivate let onlyDisabledRules: Bool

    // swiftlint:disable line_length
    static func create(_ configurationFile: String) -> (_ ruleID: String) -> (_ onlyEnabledRules: Bool) -> (_ onlyDisabledRules: Bool) -> RulesOptions {
        return { ruleID in { onlyEnabledRules in { onlyDisabledRules in
            self.init(ruleID: (ruleID.isEmpty ? nil : ruleID),
                      configurationFile: configurationFile,
                      onlyEnabledRules: onlyEnabledRules,
                      onlyDisabledRules: onlyDisabledRules)
        }}}
    }

    static func evaluate(_ mode: CommandMode) -> Result<RulesOptions, CommandantError<CommandantError<()>>> {
        return create
            <*> mode <| configOption
            <*> mode <| Argument(defaultValue: "",
                                 usage: "the rule identifier to display description for")
            <*> mode <| Switch(flag: "e",
                               key: "enabled",
                               usage: "only display enabled rules")
            <*> mode <| Switch(flag: "d",
                               key: "disabled",
                               usage: "only display disabled rules")
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
            TextTableColumn(header: "kind"),
            TextTableColumn(header: "configuration")
        ]
        self.init(columns: columns)
        let sortedRules = ruleList.list.sorted { $0.0 < $1.0 }
        func truncate(_ string: String) -> String {
            let stringWithNoNewlines = string.replacingOccurrences(of: "\n", with: "\\n")
            let minWidth = "configuration".count - "...".count
            let configurationStartColumn = 112
            let truncatedEndIndex = stringWithNoNewlines.index(
                stringWithNoNewlines.startIndex,
                offsetBy: max(minWidth, Terminal.currentWidth() - configurationStartColumn),
                limitedBy: stringWithNoNewlines.endIndex
            )
            if let truncatedEndIndex = truncatedEndIndex {
                return stringWithNoNewlines[..<truncatedEndIndex] + "..."
            }
            return stringWithNoNewlines
        }
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
                ruleType.description.kind.rawValue,
                truncate((configuredRule ?? rule).configurationDescription)
            ])
        }
    }
}

struct Terminal {
    static func currentWidth() -> Int {
        var size = winsize()
#if os(Linux)
        _ = ioctl(CInt(STDOUT_FILENO), UInt(TIOCGWINSZ), &size)
#else
        _ = ioctl(STDOUT_FILENO, TIOCGWINSZ, &size)
#endif
        return Int(size.ws_col)
    }
}
