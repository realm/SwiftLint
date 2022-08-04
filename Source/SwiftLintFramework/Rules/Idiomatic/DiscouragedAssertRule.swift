import SourceKittenFramework

public struct DiscouragedAssertRule: ASTRule, OptInRule, ConfigurationProviderRule {
    // MARK: - Properties

    public var configuration = SeverityConfiguration(.warning)

    public static let description = RuleDescription(
        identifier: "discouraged_assert",
        name: "Discouraged Assert",
        description: "Prefer `assertionFailure()` and/or `preconditionFailure()` over `assert(false)`",
        kind: .idiomatic,
        nonTriggeringExamples: [
            Example(#"assert(true)"#),
            Example(#"assert(true, "foobar")"#),
            Example(#"assert(true, "foobar", file: "toto", line: 42)"#),
            Example(#"assert(false || true)"#),
            Example(#"XCTAssert(false)"#)
        ],
        triggeringExamples: [
            Example(#"↓assert(false)"#),
            Example(#"↓assert(false, "foobar")"#),
            Example(#"↓assert(false, "foobar", file: "toto", line: 42)"#),
            Example(#"↓assert(   false    , "foobar")"#)
        ]
    )

    // MARK: - Life cycle

    public init() {}

    // MARK: - Public

    public func validate(file: SwiftLintFile,
                         kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard
            kind == .call,
            let offset = dictionary.offset,
            dictionary.name == "assert",
            isArgumentFalse(dictionary: dictionary, file: file)
        else {
            return []
        }

        return [
            StyleViolation(ruleDescription: Self.description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: offset))
        ]
    }

    // MARK: - Private

    /// Check if the single argument is `false`.
    ///
    /// Example:
    ///
    /// ```
    /// assert(false)
    /// ```
    ///
    /// - Returns: A boolean indicating if the single argument is `false`.
    private func isSingleArgumentFalse(dictionary: SourceKittenDictionary,
                                       file: SwiftLintFile) -> Bool {
        guard
            let bodyOffset = dictionary.bodyOffset,
            let bodyLength = dictionary.bodyLength,
            case let byteRange = ByteRange(location: bodyOffset, length: bodyLength),
            let argument = file.stringView.substringWithByteRange(byteRange)
        else {
            return false
        }

        return argument == "false"
    }

    /// Check if the first of multiples arguments is `false`
    ///
    /// Example:
    ///
    /// ```
    /// assert(false, "foobar")
    /// assert(false, "foobar", file: "toto")
    /// assert(false, "foobar", file: "toto", line: 42)
    /// ```
    ///
    /// - Returns: A boolean indicating if the first argument is `false`.
    private func isFirstOfMultipleArgumentsFalse(dictionary: SourceKittenDictionary,
                                                 file: SwiftLintFile) -> Bool {
        let firstArgument = dictionary.substructure
            .filter { $0.offset != nil }
            .sorted { arg1, arg2 -> Bool in
                guard
                    let firstOffset = arg1.offset,
                    let secondOffset = arg2.offset else { return false }

                return firstOffset < secondOffset
            }
            .prefix(1)
            .compactMap {
                $0.byteRange.flatMap(file.stringView.substringWithByteRange)
            }
            .first

        return firstArgument == "false"
    }

    private func isArgumentFalse(dictionary: SourceKittenDictionary,
                                 file: SwiftLintFile) -> Bool {
        isSingleArgumentFalse(dictionary: dictionary, file: file)
            || isFirstOfMultipleArgumentsFalse(dictionary: dictionary, file: file)
    }
}
