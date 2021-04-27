import SourceKittenFramework

public struct DuplicatedKeyInDictionaryLiteralRule: ASTRule, ConfigurationProviderRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static var description = RuleDescription(
        identifier: "duplicated_key_in_dictionary_literal",
        name: "Duplicated Key in Dictionary Literal",
        description: "Dictionary literals with duplicated keys will crash in runtime.",
        kind: .lint,
        nonTriggeringExamples: [
            Example("""
                [
                    1: "1",
                    2: "2"
                ]
            """),
            Example("""
                [
                    "1": 1,
                    "2": 2
                ]
            """),
            Example("""
                [
                    foo: "1",
                    bar: "2"
                ]
            """)
        ],
        triggeringExamples: [
            Example("""
                [
                    1: "1",
                    2: "2",
                    ↓1: "one"
                ]
            """),
            Example("""
                [
                    "1": 1,
                    "2": 2,
                    ↓"2": 2
                ]
            """),
            Example("""
                [
                    foo: "1",
                    bar: "2",
                    baz: "3",
                    ↓foo: "4",
                    zaz: "5"
                ]
            """),
            Example("""
                [
                    .one: "1",
                    .two: "2",
                    .three: "3",
                    ↓.one: "1",
                    .four: "4",
                    .five: "5"
                ]
            """)
        ]
    )

    public func validate(file: SwiftLintFile, kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard kind == .dictionary else {
            return []
        }

        let keys = dictionaryKeys(with: file, dictionary: dictionary)
        guard keys.count >= 2 else {
            return []
        }

        var existingKeys: [String: DictionaryKey] = [:]
        return keys
            .filter { key in
                guard let existingKey = existingKeys[key.content] else {
                    existingKeys[key.content] = key
                    return false
                }

                let existingKeyKinds = file.syntaxMap.kinds(inByteRange: existingKey.byteRange)
                let keyKinds = file.syntaxMap.kinds(inByteRange: key.byteRange)
                return keyKinds == existingKeyKinds
            }.map { key in
                StyleViolation(ruleDescription: Self.description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: key.byteRange.location))
            }
    }

    private func dictionaryKeys(with file: SwiftLintFile,
                                dictionary: SourceKittenDictionary) -> [DictionaryKey] {
        let keys = dictionary.elements.enumerated().compactMap { index, element -> SourceKittenDictionary? in
            // in a dictionary, the even elements are keys, and the odd elements are values
            if index.isMultiple(of: 2) {
                return element
            }
            return nil
        }

        let contents = file.stringView
        return keys.compactMap { key -> DictionaryKey? in
            guard let range = key.byteRange,
                  let substring = contents.substringWithByteRange(range) else {
                return nil
            }

            return DictionaryKey(byteRange: range, content: substring)
        }
    }

    private struct DictionaryKey {
        let byteRange: ByteRange
        let content: String
    }
}
