public struct DiscouragedDirectInitRule: ASTRule, ConfigurationProviderRule {
    public var configuration = DiscouragedDirectInitConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "discouraged_direct_init",
        name: "Discouraged Direct Initialization",
        description: "Discouraged direct initialization of types that can be harmful.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("let foo = UIDevice.current"),
            Example("let foo = Bundle.main"),
            Example("let foo = Bundle(path: \"bar\")"),
            Example("let foo = Bundle(identifier: \"bar\")"),
            Example("let foo = Bundle.init(path: \"bar\")"),
            Example("let foo = Bundle.init(identifier: \"bar\")")
        ],
        triggeringExamples: [
            Example("↓UIDevice()"),
            Example("↓Bundle()"),
            Example("let foo = ↓UIDevice()"),
            Example("let foo = ↓Bundle()"),
            Example("let foo = bar(bundle: ↓Bundle(), device: ↓UIDevice())"),
            Example("↓UIDevice.init()"),
            Example("↓Bundle.init()"),
            Example("let foo = ↓UIDevice.init()"),
            Example("let foo = ↓Bundle.init()"),
            Example("let foo = bar(bundle: ↓Bundle.init(), device: ↓UIDevice.init())")
        ]
    )

    public func validate(file: SwiftLintFile,
                         kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard
            kind == .call,
            let offset = dictionary.nameOffset,
            let name = dictionary.name,
            dictionary.bodyLength == 0,
            configuration.discouragedInits.contains(name)
            else {
                return []
        }

        return [StyleViolation(ruleDescription: Self.description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: offset))]
    }
}
