import SourceKittenFramework

public struct NSLocalizedStringKeyRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "nslocalizedstring_key",
        name: "NSLocalizedString Key",
        description: "Static strings should be used as key/comment" +
            " in NSLocalizedString in order for genstrings to work.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("NSLocalizedString(\"key\", comment: \"\")"),
            Example("NSLocalizedString(\"key\" + \"2\", comment: \"\")"),
            Example("NSLocalizedString(\"key\", comment: \"comment\")"),
            Example("""
            NSLocalizedString("This is a multi-" +
                "line string", comment: "")
            """),
            Example("""
            let format = NSLocalizedString("%@, %@.", comment: "Accessibility label for a post in the post list." +
            " The parameters are the title, and date respectively." +
            " For example, \"Let it Go, 1 hour ago.\"")
            """)
        ],
        triggeringExamples: [
            Example("NSLocalizedString(↓method(), comment: \"\")"),
            Example("NSLocalizedString(↓\"key_\\(param)\", comment: \"\")"),
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
        guard !kinds.allSatisfy({ $0 == .string }) else { return nil }

        return makeViolation(file: file, byteRange: byteRange)
    }

    private func getViolationForComment(file: SwiftLintFile,
                                        dictionary: SourceKittenDictionary) -> StyleViolation? {
        guard let commentArgument = dictionary.enclosedArguments
                .first(where: { $0.name == "comment" }),
              let bodyByteRange = commentArgument.bodyByteRange
        else { return nil }

        let tokens = file.syntaxMap.tokens(inByteRange: bodyByteRange)
        guard !tokens.isEmpty else { return nil }

        if tokens.allSatisfy({ $0.kind == .string }) {
            // All tokens are string literals
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
