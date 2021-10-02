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
            // Key validation
            Example(#"NSLocalizedString("key", comment: "")"#),
            Example(#"NSLocalizedString("key" + "2", comment: "")"#),
            Example("""
            NSLocalizedString("This is a multi-" +
                "line string", comment: "")
            """),
            Example(#"""
            NSLocalizedString("""
            This is a multi-line string
            """, comment: "")
            """#),
            Example("""
            let format = NSLocalizedString("%@, %@.", comment: "Accessibility label for a post in the post list." +
            " The parameters are the title, and date respectively." +
            " For example, "Let it Go, 1 hour ago.")
            """),
            Example(#"""
            let format = NSLocalizedString("%@, %@.", comment: """
            Accessibility label for a post in the post list.
            The parameters are the title, and date respectively.
            For example, "Let it Go, 1 hour ago."
            """)
            """#),
            // TableName validation
            Example(#"NSLocalizedString("key", tableName: "", comment: "")"#),
            Example(#"NSLocalizedString("key", tableName: "table", comment: "")"#),
            Example(#"NSLocalizedString("key", tableName: "table" + "2", comment: "")"#),
            Example("""
            NSLocalizedString("key", tableName: "This is a multi-" +
                "line string", comment: "")
            """),
            Example(#"""
            NSLocalizedString("key", tableName: """
            This is a multi-line string
            """, comment: "")
            """#),
            // Value validation
            Example(#"NSLocalizedString("key", value: "", comment: "")"#),
            Example(#"NSLocalizedString("key", value: "value", comment: "")"#),
            Example(#"NSLocalizedString("key", value: "value" + "2", comment: "")"#),
            Example("""
            NSLocalizedString("key", value: "This is a multi-" +
                "line string", comment: "")
            """),
            Example(#"""
            NSLocalizedString("key", value: """
            This is a multi-line string
            """, comment: "")
            """#),
            Example("""
            let format = NSLocalizedString("%@, %@.", value: "%@, %@.", comment: "Accessibility label for a post in the post list." +
            " The parameters are the title, and date respectively." +
            " For example, "Let it Go, 1 hour ago.")
            """),
            Example(#"""
            let format = NSLocalizedString("%@, %@.", value: "%@, %@.", comment: """
            Accessibility label for a post in the post list.
            The parameters are the title, and date respectively.
            For example, "Let it Go, 1 hour ago."
            """)
            """#),
            // Comment validation
            Example(#"NSLocalizedString("key", comment: "")"#),
            Example(#"NSLocalizedString("key", comment: "comment")"#),
            Example(#"NSLocalizedString("key", comment: "comment" + "2")"#),
            Example("""
            NSLocalizedString("key", comment: "This is a multi-" +
                "line string")
            """),
            Example(#"""
            NSLocalizedString("key", comment: """
            This is a multi-line string
            """)
            """#),
            // All parameters
            Example(#"NSLocalizedString("key", tableName: "Table", value: "Value", comment: "Comment")"#),
        ],
        triggeringExamples: [
            // Key validation
            Example(#"NSLocalizedString(↓method(), comment: "")"#),
            Example(#"NSLocalizedString(↓variable, comment: "")"#),
            Example(#"NSLocalizedString(↓"key_\(param)", comment: "")"#),
            Example(#"NSLocalizedString(↓"key" + 2.description, comment: "")"#),
            // Table Name validation
            Example(#"NSLocalizedString("key", tableName: ↓method(), comment: "")"#),
            Example(#"NSLocalizedString("key", tableName: ↓variable, comment: "")"#),
            Example(#"NSLocalizedString("key", tableName: ↓"table \(param)", comment: "")"#),
            Example(#"NSLocalizedString("key", tableName: ↓"table" + 2.description, comment: "")"#),
            // Value validation
            Example(#"NSLocalizedString("key", value: ↓method(), comment: "")"#),
            Example(#"NSLocalizedString("key", value: ↓variable, comment: "")"#),
            Example(#"NSLocalizedString("key", value: ↓"value \(param)", comment: "")"#),
            Example(#"NSLocalizedString("key", value: ↓"value" + 2.description, comment: "")"#),
            // Comment validation
            Example(#"NSLocalizedString("key", comment: ↓"comment with \(param)")"#),
            Example(#"NSLocalizedString("key", comment: ↓"comment with \(param)")"#),
            Example(#"NSLocalizedString(↓"key_\(param)", comment: ↓method())"#),
            Example(#"NSLocalizedString(↓"key_\(param)", comment: ↓variable)"#),
        ],
    )

    public func validate(file: SwiftLintFile,
                         kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .call, dictionary.name == "NSLocalizedString" else { return [] }

        return [
            getViolationForArgument(nil /* key */, file: file, dictionary: dictionary),
            getViolationForArgument("tableName", file: file, dictionary: dictionary),
            getViolationForArgument("value", file: file, dictionary: dictionary),
            getViolationForArgument("comment", file: file, dictionary: dictionary),
        ].compactMap { $0 }
    }

    // MARK: - Private helpers
    
    private func getViolationForArgument(_ name: String?,
                                         file: SwiftLintFile,
                                         dictionary: SourceKittenDictionary) -> StyleViolation? {
        guard let argument = dictionary.enclosedArguments
                .first(where: { $0.name == name }),
              let bodyByteRange = argument.bodyByteRange
        else { return nil }

        let tokens = file.syntaxMap.tokens(inByteRange: bodyByteRange)
        guard !tokens.isEmpty else { return nil }

        if tokens.allSatisfy({ $0.kind == .string }) {
            // All tokens are string literals
            return nil
        }
        
        return StyleViolation(ruleDescription: Self.description,
                              severity: configuration.severity,
                              location: Location(file: file, byteOffset: bodyByteRange.location))
    }
}
