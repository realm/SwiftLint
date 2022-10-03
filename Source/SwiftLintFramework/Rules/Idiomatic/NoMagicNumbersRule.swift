import SourceKittenFramework

public struct NoMagicNumbersRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public init() {}

    public init(configuration: Any) throws {}

    public var configuration = SeverityConfiguration(.warning)

    public static let description = RuleDescription(
        identifier: "no_magic_numbers",
        name: "No Magic Numbers",
        description: """
        ‘Magic numbers’ are numbers that occur multiple times in code without an explicit meaning.
        They should preferably be replaced by named constants.
        """,
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("var x = 123\nfoo(x)"),
            Example("array[0] + array[1]"),
            Example("static let foo = 0.123)")
        ],
        triggeringExamples: [
            Example("foo(123)"),
            Example("let someElement = array[98]"),
            Example("Color.primary.opacity(isAnimate ? 0.1 : 1.5)")
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        // ignore 0, 0.0, 1, and 1.0, because they're used so often
        let pattern = "([01].(0[0-9]|[1-9])[0-9_]*)|([01][0-9]|[2-9])[0-9]*\\.?[0-9_]*"
        let excludingKinds = SyntaxKind.commentAndStringKinds
        return file.match(pattern: pattern, excludingSyntaxKinds: excludingKinds).map {
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }
}
