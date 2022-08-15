public struct SuperfluousDisableCommandRule: ConfigurationProviderRule, SourceKitFreeRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "superfluous_disable_command",
        name: "Superfluous Disable Command",
        description: "SwiftLint 'disable' commands are superfluous when the disabled rule would not have " +
                     "triggered a violation in the disabled region. Use \" - \" if you wish to document a command.",
        kind: .lint
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        // This rule is implemented in Linter.swift
        return []
    }

    public func reason(for rule: Rule.Type) -> String {
        return self.reason(for: rule.description.identifier)
    }

    public func reason(for rule: String) -> String {
        """
        SwiftLint rule '\(rule)' did not trigger a violation in the disabled region. Please remove the disable command.
        """
    }

    public func reason(forNonExistentRule rule: String) -> String {
        return "'\(rule)' is not a valid SwiftLint rule. Please remove it from the disable command."
    }
}
