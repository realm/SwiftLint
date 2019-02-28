import SourceKittenFramework

public struct NSObjectPreferIsEqualRule: Rule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "nsobject_prefer_isequal",
        name: "NSObject Prefer isEqual",
        description: "NSObject subclasses should implement isEqual instead of ==.",
        kind: .lint,
        nonTriggeringExamples: NSObjectPreferIsEqualRuleExamples.nonTriggeringExamples,
        triggeringExamples: NSObjectPreferIsEqualRuleExamples.triggeringExamples
    )

    public func validate(file: File) -> [StyleViolation] {
        return []
    }
}
