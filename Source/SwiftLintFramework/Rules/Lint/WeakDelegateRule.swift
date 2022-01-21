private let printDeprecationWarning: Void = {
    queuedPrintError(
        "warning: \(WeakDelegateRule.description.description)"
    )
}()

public struct WeakDelegateRule: OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "weak_delegate",
        name: "Weak Delegate (Deprecated)",
        description:
            """
            The 'weak_delegate' rule has been deprecated due to its high false positive rate.
            The identifier will become invalid in a future release.
            """,
        kind: .lint
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        _ = printDeprecationWarning
        return []
    }
}
