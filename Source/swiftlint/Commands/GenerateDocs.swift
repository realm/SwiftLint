import ArgumentParser
import Foundation
import SwiftLintFramework

extension SwiftLint {
    struct GenerateDocs: ParsableCommand {
        static let configuration = CommandConfiguration(
            abstract: "Generates markdown documentation for selected group of rules"
        )

        @Option(help: "The directory where the documentation should be saved")
        var path = "rule_docs"
        @Option(help: "The path to a SwiftLint configuration file")
        var config: String?
        @OptionGroup
        var rulesFilterOptions: RulesFilterOptions

        func run() throws {
            let configuration = Configuration(configurationFiles: [config].compactMap({ $0 }))
            let rulesFilter = RulesFilter(enabledRules: configuration.rules)
            let rules = rulesFilter.getRules(excluding: .excludingOptions(byCommandLineOptions: rulesFilterOptions))

            try RuleListDocumentation(rules)
                .write(to: URL(fileURLWithPath: path, isDirectory: true))
            ExitHelper.successfullyExit()
        }
    }
}
