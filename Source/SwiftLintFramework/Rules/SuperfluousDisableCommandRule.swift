package struct SuperfluousDisableCommandRule: SourceKitFreeRule, Sendable {
    package var configuration = SeverityConfiguration<Self>(.warning)

    package init() { /* Make initializer as accessible as its type. */ }

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

    package func validate(file _: SwiftLintFile) -> [StyleViolation] {
        // This rule is implemented in Linter.swift
        []
    }

    func reason(forRuleIdentifier ruleIdentifier: String) -> String {
        """
        SwiftLint rule '\(ruleIdentifier)' did not trigger a violation in the disabled region; \
        remove the disable command
        """
    }

    func reason(forNonExistentRule rule: String) -> String {
        "'\(rule)' is not a valid SwiftLint rule; remove it from the disable command"
    }
}
