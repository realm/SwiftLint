import SourceKittenFramework

public struct NoMagicNumbersRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public init() {}

    public init(configuration: Any) throws {}

    public var configuration = SeverityConfiguration(.warning)

    public static let description = RuleDescription(
        identifier: "no_magic_numbers",
        name: "No Magic Numbers",
        description: "‘Magic numbers’ should be replaced by named constants.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example("""
var x = 123
foo(x)
"""),
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
        file.syntaxTokensByLines.flatMap { line -> [StyleViolation] in
            line.enumerated().compactMap { tokenIx, token -> StyleViolation? in
                guard token.kind == .number,
                      let nrString = file.contents(for: token)?.replacingOccurrences(of: "_", with: ""),
                      let number = Double(nrString),
                      ![0, 1, -1].contains(number),
                      // if it follows a `<keyword> <identifier> <number>` pattern it's (probably) a declaration (i.e. `var x = 2`)
                      tokenIx < 2 || line[tokenIx - 1].kind != .identifier || line[tokenIx - 2].kind != .keyword else {
                    return nil
                }
                return StyleViolation(
                    ruleDescription: Self.description,
                    severity: configuration.severity,
                    location: Location(file: file, characterOffset: token.offset.value))
            }
        }
    }
}
