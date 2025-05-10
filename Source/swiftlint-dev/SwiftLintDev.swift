import ArgumentParser
import Foundation

@main
struct SwiftLintDev: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swiftlint-dev",
        abstract: "A tool to help develop SwiftLint.",
        subcommands: [
            Reporters.self,
            Rules.self,
        ]
    )

    struct Reporters: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "reporters",
            abstract: "Manage SwiftLint reporters.",
            subcommands: [
                Self.Register.self,
            ]
        )
    }

    struct Rules: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "rules",
            abstract: "Manage SwiftLint rules.",
            subcommands: [
                Self.Register.self,
                Self.Template.self,
            ]
        )
    }
}

extension URL {
    var relativeToCurrentDirectory: String {
        String(path.replacingOccurrences(of: FileManager.default.currentDirectoryPath, with: "").dropFirst())
    }
}
