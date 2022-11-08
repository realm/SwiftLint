import ArgumentParser
import Foundation
import SwiftLintFramework

@main
struct SwiftLint: AsyncParsableCommand {
    static let configuration: CommandConfiguration = {
        if let directory = ProcessInfo.processInfo.environment["BUILD_WORKSPACE_DIRECTORY"] {
            FileManager.default.changeCurrentDirectoryPath(directory)
        }

        RuleRegistry.registerAllRulesOnce()

        return CommandConfiguration(
            commandName: "swiftlint",
            abstract: "A tool to enforce Swift style and conventions.",
            version: Version.value,
            subcommands: [
                Analyze.self,
                Docs.self,
                GenerateDocs.self,
                Lint.self,
                Rules.self,
                Version.self
            ],
            defaultSubcommand: Lint.self
        )
    }()
}
