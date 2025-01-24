import Foundation

struct InvalidSwiftLintCommandRule: Rule, SourceKitFreeRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "invalid_swiftlint_command",
        name: "Invalid SwiftLint Command",
        description: "swiftlint command is invalid",
        kind: .lint,
        nonTriggeringExamples: [
            Example("// swiftlint:disable unused_import"),
            Example("// swiftlint:enable unused_import"),
            Example("// swiftlint:disable:next unused_import"),
            Example("// swiftlint:disable:previous unused_import"),
            Example("// swiftlint:disable:this unused_import"),
            Example("//swiftlint:disable:this unused_import"),
            Example("_ = \"🤵🏼‍♀️\" // swiftlint:disable:this unused_import", excludeFromDocumentation: true),
            Example("_ = \"🤵🏼‍♀️ 🤵🏼‍♀️\" // swiftlint:disable:this unused_import", excludeFromDocumentation: true),
        ],
        triggeringExamples: [
            Example("// ↓swiftlint:"),
            Example("// ↓swiftlint: "),
            Example("// ↓swiftlint::"),
            Example("// ↓swiftlint:: "),
            Example("// ↓swiftlint:disable"),
            Example("// ↓swiftlint:dissable unused_import"),
            Example("// ↓swiftlint:enaaaable unused_import"),
            Example("// ↓swiftlint:disable:nxt unused_import"),
            Example("// ↓swiftlint:enable:prevus unused_import"),
            Example("// ↓swiftlint:enable:ths unused_import"),
            Example("// ↓swiftlint:enable"),
            Example("// ↓swiftlint:enable:"),
            Example("// ↓swiftlint:enable: "),
            Example("// ↓swiftlint:disable: unused_import"),
            Example("// s↓swiftlint:disable unused_import"),
            Example("// 🤵🏼‍♀️swiftlint:disable unused_import", excludeFromDocumentation: true),
        ].skipWrappingInCommentTests()
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        badPrefixViolations(in: file) + invalidCommandViolations(in: file)
    }

    private func badPrefixViolations(in file: SwiftLintFile) -> [StyleViolation] {
        (file.commands + file.invalidCommands).compactMap { command in
            command.isPrecededByInvalidCharacter(in: file)
                ? styleViolation(
                    for: command,
                    in: file,
                    reason: "swiftlint command should be preceded by whitespace or a comment character"
                )
                : nil
        }
    }

    private func invalidCommandViolations(in file: SwiftLintFile) -> [StyleViolation] {
        file.invalidCommands.map { command in
            styleViolation(for: command, in: file, reason: command.invalidReason() ?? Self.description.description)
        }
    }

    private func styleViolation(for command: Command, in file: SwiftLintFile, reason: String) -> StyleViolation {
        StyleViolation(
            ruleDescription: Self.description,
            severity: configuration.severity,
            location: Location(file: file.path, line: command.line, character: command.character),
            reason: reason
        )
    }
}

private extension Command {
    func isPrecededByInvalidCharacter(in file: SwiftLintFile) -> Bool {
        guard line > 0, let character, character > 1, line <= file.lines.count else {
            return false
        }
        let line = file.lines[line - 1].content
        guard line.count > character,
              let char = line[line.index(line.startIndex, offsetBy: character - 2)].unicodeScalars.first else {
            return false
        }
        return !CharacterSet.whitespaces.union(CharacterSet(charactersIn: "/")).contains(char)
    }

    func invalidReason() -> String? {
        if action == .invalid {
            return "swiftlint command does not have a valid action"
        }
        if modifier == .invalid {
            return "swiftlint command does not have a valid modifier"
        }
        if ruleIdentifiers.isEmpty {
            return "swiftlint command does not specify any rules"
        }
        return nil
    }
}
