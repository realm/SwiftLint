import Foundation
import SourceKittenFramework

public struct DiscouragedAssertRule: ASTRule, OptInRule, ConfigurationProviderRule, AutomaticTestableRule {
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
            Example(#"assert(true, "foobar", file: "toto", line: 42)"#)
        ],
        triggeringExamples: [
            Example(#"↓assert(false)"#),
            Example(#"↓assert(false, "foobar")"#),
            Example(#"↓assert(false, "foobar", file: "toto", line: 42)"#),
            Example(#"↓assert(   false    , "foobar")"#)
        ]
    )

    // MARK: - Nested types

    private enum DiscouragedAssertError: Error {
        case missingArgument
        case missingArguments
    }

    // MARK: - Life cycle

    public init() {}

    // MARK: - Public

    public func validate(file: SwiftLintFile,
                         kind: SwiftExpressionKind,
                         dictionary: SourceKittenDictionary) -> [StyleViolation] {
        guard
            kind == .call,
            let offset = dictionary.offset,
            dictionary.name == "assert"
        else {
            return []
        }

        let isSingleFalse = try? isSingleArgumentFalse(dictionary: dictionary, file: file)
        let isFirstOfMultiplesFalse = try? isFirstOfMultipleArgumentsFalse(dictionary: dictionary, file: file)

        guard isSingleFalse == true || isFirstOfMultiplesFalse == true else {
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
                                       file: SwiftLintFile) throws -> Bool {
        guard
            let bodyOffset = dictionary.bodyOffset,
            let bodyLength = dictionary.bodyLength,
            case let byteRange = ByteRange(location: bodyOffset, length: bodyLength),
            let argument = file.stringView.substringWithByteRange(byteRange)
        else {
            throw DiscouragedAssertError.missingArgument
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
                                                 file: SwiftLintFile) throws -> Bool {
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

        guard let argument = firstArgument else {
            throw DiscouragedAssertError.missingArguments
        }

        return argument == "false"
    }
}
