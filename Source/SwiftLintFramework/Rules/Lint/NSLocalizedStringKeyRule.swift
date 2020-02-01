import SourceKittenFramework

public struct NSLocalizedStringKeyRule: ASTRule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "nslocalizedstring_key",
        name: "NSLocalizedString Key",
        description: "Static strings should be used as key in NSLocalizedString in order to genstrings work.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("NSLocalizedString(\"key\", comment: nil)"),
            Example("NSLocalizedString(\"key\" + \"2\", comment: nil)")
        ],
        triggeringExamples: [
            Example("NSLocalizedString(↓method(), comment: nil)"),
            Example("NSLocalizedString(↓\"key_\\(param)\", comment: nil)")
        ]
    )

    public func validate(file: SwiftLintFile,
                         kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .call,
            dictionary.name == "NSLocalizedString",
            let firstArgument = dictionary.enclosedArguments.first,
            firstArgument.name == nil,
            let byteRange = firstArgument.byteRange,
            case let kinds = file.syntaxMap.kinds(inByteRange: byteRange),
            !kinds.allSatisfy({ $0 == .string }) else {
                return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: byteRange.location))
        ]
    }
}
