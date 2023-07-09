import ArgumentParser
#if canImport(Darwin)
import Darwin
#elseif canImport(Glibc)
import Glibc
#else
#error("Unsupported platform")
#endif
import Foundation
import SwiftLintFramework
import SwiftyTextTable

extension SwiftLint {
    struct Rules: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Display the list of rules and their identifiers")

        @Option(help: "The path to a SwiftLint configuration file")
        var config: String?
        @OptionGroup
        var rulesFilterOptions: RulesFilterOptions
        @Flag(name: .shortAndLong, help: "Display full configuration details")
        var verbose = false
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
            let rulesFilter = RulesFilter(enabledRules: configuration.rules)
            let rules = rulesFilter.getRules(excluding: .excludingOptions(byCommandLineOptions: rulesFilterOptions))
            let table = TextTable(ruleList: rules, configuration: configuration, verbose: verbose)
            print(table.render())
            ExitHelper.successfullyExit()
        }

        func printDescription(for ruleType: Rule.Type, with configuration: Configuration) {
            let description = ruleType.description
            print("\(description.consoleDescription)")

            let rule = configuration.configuredRule(forID: ruleType.identifier) ?? ruleType.init()
            if rule.configurationDescription.hasContent {
                print("\nConfiguration (YAML):\n")
                print("  \(description.identifier):")
                print(rule.configurationDescription.yaml().indent(by: 4))
            }

            guard description.triggeringExamples.isNotEmpty else { return }

            print("\nTriggering Examples (violations are marked with '↓'):")
            for (index, example) in description.triggeringExamples.enumerated() {
                print("\nExample #\(index + 1)\n\n\(example.code.indent(by: 4))")
            }
        }
    }
}

// MARK: - SwiftyTextTable

private extension TextTable {
    init(ruleList: RuleList, configuration: Configuration, verbose: Bool) {
        let columns = [
            TextTableColumn(header: "identifier"),
            TextTableColumn(header: "opt-in"),
            TextTableColumn(header: "correctable"),
            TextTableColumn(header: "enabled in your config"),
            TextTableColumn(header: "kind"),
            TextTableColumn(header: "analyzer"),
            TextTableColumn(header: "uses sourcekit"),
            TextTableColumn(header: "configuration")
        ]
        self.init(columns: columns)
        let sortedRules = ruleList.list.sorted { $0.0 < $1.0 }
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
        for (ruleID, ruleType) in sortedRules {
            let rule = ruleType.init()
            let configuredRule = configuration.configuredRule(forID: ruleID)
            addRow(values: [
                ruleID,
                (rule is OptInRule) ? "yes" : "no",
                (rule is CorrectableRule) ? "yes" : "no",
                configuredRule != nil ? "yes" : "no",
                ruleType.description.kind.rawValue,
                (rule is AnalyzerRule) ? "yes" : "no",
                (rule is SourceKitFreeRule) ? "no" : "yes",
                truncate((configuredRule ?? rule).configurationDescription.oneLiner())
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
