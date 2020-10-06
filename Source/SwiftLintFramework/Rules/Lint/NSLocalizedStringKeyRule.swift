import SourceKittenFramework

public struct NSLocalizedStringKeyRule: ASTRule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "nslocalizedstring_key",
        name: "NSLocalizedString Key",
        description: "Static strings should be used as key/comment" +
            " in NSLocalizedString in order for genstrings to work.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("NSLocalizedString(\"key\", comment: nil)"),
            Example("NSLocalizedString(\"key\" + \"2\", comment: nil)"),
            Example("NSLocalizedString(\"key\", comment: \"comment\")")
        ],
        triggeringExamples: [
            Example("NSLocalizedString(↓method(), comment: nil)"),
            Example("NSLocalizedString(↓\"key_\\(param)\", comment: nil)"),
            Example("NSLocalizedString(\"key\", comment: ↓\"comment with \\(param)\")"),
            Example("NSLocalizedString(↓\"key_\\(param)\", comment: ↓method())")
        ]
    )

    public func validate(file: SwiftLintFile,
                         kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .call, dictionary.name == "NSLocalizedString" else { return [] }

        return [
            getViolationForKey(file: file, dictionary: dictionary),
            getViolationForComment(file: file, dictionary: dictionary)
        ].compactMap { $0 }
    }

    // MARK: - Private helpers

    private func getViolationForKey(file: SwiftLintFile,
                                    dictionary: SourceKittenDictionary) -> StyleViolation? {
        guard let keyArgument = dictionary.enclosedArguments
                .first(where: { $0.name == nil }),
              let byteRange = keyArgument.byteRange
        else { return nil }

        let kinds = file.syntaxMap.kinds(inByteRange: byteRange)
        if kinds.contains(where: { $0 != .string }) {
            return makeViolation(file: file, byteRange: byteRange)
        } else {
            return nil
        }
    }

    private func getViolationForComment(file: SwiftLintFile,
                                        dictionary: SourceKittenDictionary) -> StyleViolation? {
        guard let commentArgument = dictionary.enclosedArguments
                .first(where: { $0.name == "comment" }),
              let bodyByteRange = commentArgument.bodyByteRange
        else { return nil }

        let tokens = file.syntaxMap.tokens(inByteRange: bodyByteRange)
        guard tokens.count == 1 else {
            return makeViolation(file: file, byteRange: bodyByteRange)
        }

        let commentToken = tokens[0]
        if commentToken.kind == .string {
            // No violation if static string is used
            return nil
        }

        let commentValue = file.stringView.substringWithByteRange(bodyByteRange) ?? ""
        if commentToken.kind == .keyword && commentValue == "nil" {
            // No violation is nil is used
            return nil
        }

        return makeViolation(file: file, byteRange: bodyByteRange)
    }

    private func makeViolation(file: SwiftLintFile, byteRange: ByteRange) -> StyleViolation {
        StyleViolation(ruleDescription: Self.description,
                       severity: configuration.severity,
                       location: Location(file: file, byteOffset: byteRange.location))
    }
}
