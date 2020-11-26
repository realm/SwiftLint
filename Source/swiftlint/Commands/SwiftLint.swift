import ArgumentParser
import Foundation

struct SwiftLint: ParsableCommand {
    static var configuration = CommandConfiguration(
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

    // Temporary convenience to help migrate users to the new command.
    static func mainHandlingDeprecatedCommands(_ arguments: [String]? = nil) {
        let argumentsToCheck = arguments ?? Array(CommandLine.arguments.dropFirst())
        guard argumentsToCheck.first == "autocorrect" else {
            main(arguments)
            return
        }

        fputs(
            """
            The `swiftlint autocorrect` command is no longer available.
            Please use `swiftlint --fix` instead.

            """,
            stderr
        )
        var newArguments = argumentsToCheck
        newArguments[0] = "--fix"
        main(newArguments)
    }
}
