@_spi(TestHelper)
public struct SuperfluousDisableCommandRule: ConfigurationProviderRule, SourceKitFreeRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "superfluous_disable_command",
        name: "Superfluous Disable Command",
        description: """
            SwiftLint 'disable' commands are superfluous when the disabled rule would not have triggered a violation \
            in the disabled region. Use " - " if you wish to document a command.
            """,
        kind: .lint
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        // This rule is implemented in Linter.swift
        return []
    }

    func reason(for rule: Rule.Type) -> String {
        """
        SwiftLint rule '\(rule.description.identifier)' did not trigger a violation in the disabled region; \
        remove the disable command
        """
    }

    func reason(forNonExistentRule rule: String) -> String {
        return "'\(rule)' is not a valid SwiftLint rule; remove it from the disable command"
    }
}
