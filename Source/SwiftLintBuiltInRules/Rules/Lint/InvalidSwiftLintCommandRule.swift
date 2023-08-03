struct InvalidSwiftLintCommandRule: ConfigurationProviderRule {
    var configuration = SeverityConfiguration<Self>(.warning)

    static let description = RuleDescription(
        identifier: "invalid_swiftlint_command",
        name: "Invalid SwiftLint Command",
        description: "swiftlint command does not have a valid action or modifier",
        kind: .lint,
        nonTriggeringExamples: [
            "// swiftlint:disable unused_import",
            "// swiftlint:enable unused_import",
            "// swiftlint:disable:next unused_import",
            "// swiftlint:disable:previous unused_import",
            "// swiftlint:disable:this unused_import"
        ],
        triggeringExamples: [
            "// swiftlint:",
            "// swiftlint: ",
            "// swiftlint::",
            "// swiftlint:: ",
            "// swiftlint:disable",
            "// swiftlint:dissable unused_import",
            "// swiftlint:enaaaable unused_import",
            "// swiftlint:disable:nxt unused_import",
            "// swiftlint:enable:prevus unused_import",
            "// swiftlint:enable:ths unused_import",
            "// swiftlint:enable",
            "// swiftlint:enable:",
            "// swiftlint:enable: ",
            "// swiftlint:disable: unused_import"
        ].skipWrappingInCommentTests()
    )

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        file.invalidCommands.map {
            let location = Location(file: file.path, line: $0.line, character: $0.character)
            return StyleViolation(
                ruleDescription: Self.description,
                severity: configuration.severity,
                location: location
            )
        }
    }
}
