struct InvalidSwiftLintCommandRule: ConfigurationProviderRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "invalid_swiftlint_command",
        name: "Invalid SwiftLint Command",
        description: "swiftlint command does not have a valid action or modifier",
        kind: .lint,
        nonTriggeringExamples: [
            Example("// swiftlint:disable unused_import"),
            Example("// swiftlint:enable unused_import"),
            Example("// swiftlint:disable:next unused_import"),
            Example("// swiftlint:disable:previous unused_import"),
            Example("// swiftlint:disable:this unused_import")
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
            Example("// s↓swiftlint:disable unused_import")
        ].skipWrappingInCommentTests()
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        validateBadPrefixViolations(file: file) + validateInvalidCommandViolations(file: file)
    }
    
    private func validateBadPrefixViolations(file: SwiftLintFile) -> [StyleViolation] {
        (file.commands + file.invalidCommands).compactMap { command in
            if let precedingCharacter = command.precedingCharacter(in: file) {
                if precedingCharacter != " ", precedingCharacter != "/", precedingCharacter != "*" {
                    let location = Location(file: file.path, line: command.line, character: command.startingCharacterPosition(in: file))
                    return StyleViolation(
                        ruleDescription: Self.description,
                        severity: configuration.severity,
                        location: location,
                        reason: "swiftlint command should be preceded by whitespace or a comment character"
                    )
                }
            }
            return nil
        }
    }
    
    private func validateInvalidCommandViolations(file: SwiftLintFile) -> [StyleViolation] {
        file.invalidCommands.map { command in
            let character = command.startingCharacterPosition(in: file)
            let location = Location(file: file.path, line: command.line, character: character)
            return StyleViolation(
                ruleDescription: Self.description,
                severity: configuration.severity,
                location: location,
                reason: command.invalidReason() ?? Self.description.description
            )
        }
    }
}

private extension Command {
    func startingCharacterPosition(in file: SwiftLintFile) -> Int? {
        var position = character
        if line > 0, line <= file.lines.count {
            let line = file.lines[line - 1].content
            if let commandIndex = line.range(of: "swiftlint:")?.lowerBound {
                position = line.distance(from: line.startIndex, to: commandIndex) + 1
            }
        }
        return position
    }
    
    func precedingCharacter(in file: SwiftLintFile) -> String? {
        if let startingCharacterPosition = startingCharacterPosition(in: file), startingCharacterPosition > 2 {
            let line = file.lines[line - 1].content
            return line.substring(from: startingCharacterPosition - 2, length: 1)
        }
        return nil
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
