import ArgumentParser
import Foundation
import SwiftLintFramework

extension SwiftLint {
    struct GenerateDocs: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Generates markdown documentation for all rules")

        @Option(help: "The directory where the documentation should be saved")
        var path = "rule_docs"

        func run() throws {
            try RuleListDocumentation(primaryRuleList)
                .write(to: URL(fileURLWithPath: path, isDirectory: true))
        }
    }
}
