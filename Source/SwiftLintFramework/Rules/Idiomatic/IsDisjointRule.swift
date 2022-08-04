import SourceKittenFramework

public struct IsDisjointRule: ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "is_disjoint",
        name: "Is Disjoint",
        description: "Prefer using `Set.isDisjoint(with:)` over `Set.intersection(_:).isEmpty`.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("_ = Set(syntaxKinds).isDisjoint(with: commentAndStringKindsSet)"),
            Example("let isObjc = !objcAttributes.isDisjoint(with: dictionary.enclosedSwiftAttributes)"),
            Example("_ = Set(syntaxKinds).intersection(commentAndStringKindsSet)"),
            Example("_ = !objcAttributes.intersection(dictionary.enclosedSwiftAttributes)")
        ],
        triggeringExamples: [
            Example("_ = Set(syntaxKinds).↓intersection(commentAndStringKindsSet).isEmpty"),
            Example("let isObjc = !objcAttributes.↓intersection(dictionary.enclosedSwiftAttributes).isEmpty")
        ]
    )

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let pattern = "\\bintersection\\(\\S+\\)\\.isEmpty"
        let excludingKinds = SyntaxKind.commentAndStringKinds
        return file.match(pattern: pattern, excludingSyntaxKinds: excludingKinds).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }
}
