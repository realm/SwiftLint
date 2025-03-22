import ArgumentParser

@main
struct SwiftLintDev: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swiftlint-dev",
        abstract: "A tool to help develop SwiftLint.",
        subcommands: [
            RuleTemplate.self,
        ]
    )
}
