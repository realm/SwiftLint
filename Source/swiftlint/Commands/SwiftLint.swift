import ArgumentParser
import Foundation
import SwiftLintFramework

#if swift(<5.9)
#error("SwiftLint requires Swift 5.9 or later to build")
#endif

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
                ReportBaseline.self,
                Reporters.self,
                Rules.self,
                Version.self
            ],
            defaultSubcommand: Lint.self
        )
    }()
}
