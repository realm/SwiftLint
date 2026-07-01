import Foundation
import SourceKittenFramework
import SwiftLintCore

struct InvalidSwiftLintCommandRule: Rule, SourceKitFreeRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "invalid_swiftlint_command",
        name: "Invalid SwiftLint Command",
        description: "swiftlint command is invalid",
        kind: .lint,
        nonTriggeringExamples: #examples([
            "// swiftlint:disable unused_import",
            "// swiftlint:enable unused_import",
            "// swiftlint:disable:next unused_import",
            "// swiftlint:disable:previous unused_import",
            "// swiftlint:disable:this unused_import",
            "//swiftlint:disable:this unused_import",
            "_ = \"🤵🏼‍♀️\" // swiftlint:disable:this unused_import".excludeFromDocumentation(),
            "_ = \"🤵🏼‍♀️ 🤵🏼‍♀️\" // swiftlint:disable:this unused_import".excludeFromDocumentation(),
        ]),
        triggeringExamples: #examples([
            "// ↓swiftlint:",
            "// ↓swiftlint: ",
            "// ↓swiftlint::",
            "// ↓swiftlint:: ",
            "// ↓swiftlint:disable",
            "// ↓swiftlint:dissable unused_import",
            "// ↓swiftlint:enaaaable unused_import",
            "// ↓swiftlint:disable:nxt unused_import",
            "// ↓swiftlint:enable:prevus unused_import",
            "// ↓swiftlint:enable:ths unused_import",
            "// ↓swiftlint:enable",
            "// ↓swiftlint:enable:",
            "// ↓swiftlint:enable: ",
            "// ↓swiftlint:disable: unused_import",
            "// s↓swiftlint:disable unused_import",
            "// 🤵🏼‍♀️swiftlint:disable unused_import".excludeFromDocumentation(),
        ]).skipWrappingInCommentTests()
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
            location: Location(file: file.path, line: command.line, character: command.range?.lowerBound),
            reason: reason
        )
    }
}

private extension Command {
    func isPrecededByInvalidCharacter(in file: SwiftLintFile) -> Bool {
        guard line > 0, let character = range?.lowerBound, character > 1, line <= file.lines.count else {
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
