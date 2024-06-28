package struct SuperfluousDisableCommandRule: SourceKitFreeRule {
    package var configuration = SeverityConfiguration<Self>(.warning)

    package init() {}

    package static let description = RuleDescription(
        identifier: "superfluous_disable_command",
        name: "Superfluous Disable Command",
        description: """
            SwiftLint 'disable' commands are superfluous when the disabled rule would not have triggered a violation \
            in the disabled region. Use " - " if you wish to document a command.
            """,
        kind: .lint,
        nonTriggeringExamples: [
            Example("let abc:Void // swiftlint:disable:this colon"),
            Example("""
                // swiftlint:disable colon
                let abc:Void
                // swiftlint:enable colon
                """),
        ],
        triggeringExamples: [
            Example("let abc: Void // swiftlint:disable:this colon"),
            Example("""
                // swiftlint:disable colon
                let abc: Void
                // swiftlint:enable colon
                """),
        ]
    )

    package func validate(file: SwiftLintFile) -> [StyleViolation] {
        // This rule is implemented in Linter.swift
        return []
    }

    func reason(for rule: (some Rule).Type) -> String {
        """
        SwiftLint rule '\(rule.description.identifier)' did not trigger a violation in the disabled region; \
        remove the disable command
        """
    }

    func reason(forNonExistentRule rule: String) -> String {
        return "'\(rule)' is not a valid SwiftLint rule; remove it from the disable command"
    }
}
