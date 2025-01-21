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
            Example("_ = \"🤵🏼‍♀️\" // swiftlint:disable:this unused_import"),
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
        ].skipWrappingInCommentTests()
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        badPrefixViolations(in: file) + invalidCommandViolations(in: file)
    }

    private func badPrefixViolations(in file: SwiftLintFile) -> [StyleViolation] {
        (file.commands + file.invalidCommands).compactMap { command in
            if let precedingCharacter = command.precedingCharacter(in: file)?.unicodeScalars.first,
               !CharacterSet.whitespaces.union(CharacterSet(charactersIn: "/")).contains(precedingCharacter) {
                return styleViolation(
                    for: command,
                    in: file,
                    reason: "swiftlint command should be preceded by whitespace or a comment character"
                )
            }
            return nil
        }
    }

    private func invalidCommandViolations(in file: SwiftLintFile) -> [StyleViolation] {
        file.invalidCommands.map { command in
            styleViolation(for: command, in: file, reason: command.invalidReason() ?? Self.description.description)
        }
    }

    private func styleViolation(for command: Command, in file: SwiftLintFile, reason: String) -> StyleViolation {
        let character = command.startingCharacterPosition(in: file)
        let characterOffset = character.flatMap {
            if let line = command.lineOfCommand(in: file) {
                return line.distance(from: line.startIndex, to: $0)
            }
            return nil
        }
        return StyleViolation(
            ruleDescription: Self.description,
            severity: configuration.severity,
            location: Location(file: file.path, line: command.line, character: characterOffset),
            reason: reason
        )
    }
}

private extension Command {
    func lineOfCommand(in file: SwiftLintFile) -> String? {
        guard line > 0, line <= file.lines.count else {
            return nil
        }
        return file.lines[line - 1].content
    }

    func startingCharacterPosition(in file: SwiftLintFile) -> String.Index? {
        guard let line = lineOfCommand(in: file), line.isNotEmpty else {
            return nil
        }
        if let commandIndex = line.range(of: "swiftlint:")?.lowerBound {
            let distance = line.distance(from: line.startIndex, to: commandIndex)
            return line.index(line.startIndex, offsetBy: distance + 1)
        }
        if let character {
            return line.index(line.startIndex, offsetBy: character)
        }
        return nil
    }

    func precedingCharacter(in file: SwiftLintFile) -> Character? {
        guard let startingCharacterPosition = startingCharacterPosition(in: file),
              let line = lineOfCommand(in: file) else {
            return nil
        }
        guard line.distance(from: line.startIndex, to: startingCharacterPosition) > 2 else {
            return nil
        }
        return line[line.index(startingCharacterPosition, offsetBy: -2)...].first
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
