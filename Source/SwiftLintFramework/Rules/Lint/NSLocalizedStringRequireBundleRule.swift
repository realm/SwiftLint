public struct NSLocalizedStringRequireBundleRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "nslocalizedstring_require_bundle",
        name: "NSLocalizedString Require Bundle",
        description: "Calls to NSLocalizedString should specify the bundle which contains the strings file.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
            NSLocalizedString("someKey", bundle: .main, comment: "test")
            """),
            Example("""
            NSLocalizedString("someKey", tableName: "a",
                              bundle: Bundle(for: A.self),
                              comment: "test")
            """),
            Example("""
            NSLocalizedString("someKey", tableName: "xyz",
                              bundle: someBundle, value: "test"
                              comment: "test")
            """),
            Example("""
            arbitraryFunctionCall("something")
            """)
        ],
        triggeringExamples: [
            Example("""
            ↓NSLocalizedString("someKey", comment: "test")
            """),
            Example("""
            ↓NSLocalizedString("someKey", tableName: "a", comment: "test")
            """),
            Example("""
            ↓NSLocalizedString("someKey", tableName: "xyz",
                              value: "test", comment: "test")
            """)
        ]
    )

    public func validate(file: SwiftLintFile,
                         kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        let isBundleArgument: (SourceKittenDictionary) -> Bool = { $0.name == "bundle" }
        guard kind == .call,
            dictionary.name == "NSLocalizedString",
            let offset = dictionary.offset,
            !dictionary.enclosedArguments.contains(where: isBundleArgument) else {
            return []
        }

        return [
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }
}
