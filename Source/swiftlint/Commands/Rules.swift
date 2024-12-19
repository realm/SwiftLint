import ArgumentParser
import Foundation
import SwiftLintFramework
import SwiftyTextTable

private typealias SortedRules = [(String, any Rule.Type)]

extension SwiftLint {
    struct Rules: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Display the list of rules and their identifiers")

        @Option(help: "The path to a SwiftLint configuration file")
        var config: String?
        @OptionGroup
        var rulesFilterOptions: RulesFilterOptions
        @Flag(name: .shortAndLong, help: "Display full configuration details")
        var verbose = false
        @Flag(help: "Print only the YAML configuration(s)")
        var configOnly = false
        @Flag(help: "Print default configuration(s)")
        var defaultConfig = false
        @Argument(help: "The rule identifier to display description for")
        var ruleID: String?

        func run() throws {
            let configuration = Configuration(configurationFiles: [config].compactMap({ $0 }))
            if let ruleID {
                guard let rule = RuleRegistry.shared.rule(forID: ruleID) else {
                    throw SwiftLintError.usageError(description: "No rule with identifier: \(ruleID)")
                }
                printDescription(for: rule, with: configuration)
                return
            }
            let rules = RulesFilter(enabledRules: configuration.rules)
                .getRules(excluding: rulesFilterOptions.excludingOptions)
                .list
                .sorted { $0.0 < $1.0 }
            if configOnly {
                rules
                    .map(\.value)
                    .map { createInstance(of: $0, using: configuration, configure: !defaultConfig) }
                    .forEach { printConfig(for: $0) }
            } else {
                let table = TextTable(
                    ruleList: rules,
                    configuration: configuration,
                    verbose: verbose,
                    defaultConfig: defaultConfig
                )
                print(table.render())
            }
        }

        private func printDescription(for ruleType: any Rule.Type, with configuration: Configuration) {
            let description = ruleType.description

            let rule = createInstance(of: ruleType, using: configuration, configure: !defaultConfig)
            if configOnly {
                printConfig(for: rule)
                return
            }

            print("\(description.consoleDescription)")
            let configDescription = rule.createConfigurationDescription()
            if configDescription.hasContent {
                print("\nConfiguration (YAML):\n")
                print("  \(description.identifier):")
                print(configDescription.yaml().indent(by: 4))
            }

            guard description.triggeringExamples.isNotEmpty else { return }

            print("\nTriggering Examples (violations are marked with '↓'):")
            for (index, example) in description.triggeringExamples.enumerated() {
                print("\nExample #\(index + 1)\n\n\(example.code.indent(by: 4))")
            }
        }

        private func printConfig(for rule: any Rule) {
            let configDescription = rule.createConfigurationDescription()
            if configDescription.hasContent {
                print("\(type(of: rule).identifier):")
                print(configDescription.yaml().indent(by: 2))
            }
        }

        private func createInstance(of ruleType: any Rule.Type,
                                    using config: Configuration,
                                    configure: Bool) -> any Rule {
            configure
                ? config.configuredRule(forID: ruleType.identifier) ?? ruleType.init()
                : ruleType.init()
        }
    }
}

// MARK: - SwiftyTextTable

private extension TextTable {
    init(ruleList: SortedRules, configuration: Configuration, verbose: Bool, defaultConfig: Bool) {
        let columns = [
            TextTableColumn(header: "identifier"),
            TextTableColumn(header: "opt-in"),
            TextTableColumn(header: "correctable"),
            TextTableColumn(header: "enabled in your config"),
            TextTableColumn(header: "kind"),
            TextTableColumn(header: "analyzer"),
            TextTableColumn(header: "uses sourcekit"),
            TextTableColumn(header: "configuration"),
        ]
        self.init(columns: columns)
        func truncate(_ string: String) -> String {
            let stringWithNoNewlines = string.replacingOccurrences(of: "\n", with: "\\n")
            let minWidth = "configuration".count - "...".count
            let configurationStartColumn = 140
            let maxWidth = verbose ? Int.max : Terminal.currentWidth()
            let truncatedEndIndex = stringWithNoNewlines.index(
                stringWithNoNewlines.startIndex,
                offsetBy: max(minWidth, maxWidth - configurationStartColumn),
                limitedBy: stringWithNoNewlines.endIndex
            )
            if let truncatedEndIndex {
                return stringWithNoNewlines[..<truncatedEndIndex] + "..."
            }
            return stringWithNoNewlines
        }
        for (ruleID, ruleType) in ruleList {
            let rule = ruleType.init()
            let configuredRule = configuration.configuredRule(forID: ruleID)
            addRow(values: [
                ruleID,
                (rule is any OptInRule) ? "yes" : "no",
                (rule is any CorrectableRule) ? "yes" : "no",
                configuredRule != nil ? "yes" : "no",
                ruleType.description.kind.rawValue,
                (rule is any AnalyzerRule) ? "yes" : "no",
                (rule is any SourceKitFreeRule) ? "no" : "yes",
                truncate((defaultConfig ? rule : configuredRule ?? rule).createConfigurationDescription().oneLiner()),
            ])
        }
    }
}

private struct Terminal {
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
