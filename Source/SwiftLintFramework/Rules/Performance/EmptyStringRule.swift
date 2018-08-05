import SourceKittenFramework

public struct EmptyStringRule: ConfigurationProviderRule, OptInRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "empty_string",
        name: "Empty String",
        description: "Prefer checking `isEmpty` over comparing `string` to an empty string literal.",
        kind: .performance,
        nonTriggeringExamples: [
            "myString.isEmpty",
            "!myString.isEmpy"
        ],
        triggeringExamples: [
            "myString↓ == \"\"",
            "myString↓ != \"\""
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let pattern = "\\b\\s*(==|!=)\\s*\"\""
        return file.match(pattern: pattern, with: [.string]).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }
}
