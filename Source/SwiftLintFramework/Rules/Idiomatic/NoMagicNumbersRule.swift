import SourceKittenFramework

public struct NoMagicNumbersRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public init() {}

    public init(configuration: Any) throws {}

    public var configuration = SeverityConfiguration(.warning)

    public static let description = RuleDescription(
        identifier: "no_magic_numbers",
        name: "No Magic Numbers",
        description: "‘Magic numbers’ are numbers that occur multiple times in code without an explicit meaning. They should preferably be replaced by named constants.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("foo(1.0)"),
            Example("var = 123"),
            Example("static let foo = 0.123)")
        ],
        triggeringExamples: [
            Example("foo(123)"),
            Example(".fill(Color.primary.opacity(isAnimate ? 0.1 : 1.5 ))")
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        let pattern = "([01].(0[0-9]|[1-9])[0-9_]*)|([01][0-9]|[2-9])[0-9]*\\.?[0-9_]*"
        let excludingKinds = SyntaxKind.commentAndStringKinds
        return file.match(pattern: pattern, excludingSyntaxKinds: excludingKinds).map {
            print($0)
            return StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }
}
