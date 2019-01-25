import Foundation
import SourceKittenFramework

public struct IdenticalOperandsRule: ConfigurationProviderRule, OptInRule, AutomaticTestableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    private static let operators = ["==", "!=", "===", "!==", ">", ">=", "<", "<="]

    public static let description = RuleDescription(
        identifier: "identical_operands",
        name: "Identical Operands",
        description: "Comparing two identical operands is likely a mistake.",
        kind: .lint,
        nonTriggeringExamples: operators.flatMap { operation in
            [
                "1 \(operation) 2",
                "foo \(operation) bar",
                "prefixedFoo \(operation) foo",
                "foo.aProperty \(operation) foo.anotherProperty",
                "self.aProperty \(operation) self.anotherProperty",
                "\"1 \(operation) 1\"",
                "self.aProperty \(operation) aProperty",
                "lhs.aProperty \(operation) rhs.aProperty",
                "lhs.identifier \(operation) rhs.identifier",
                "i \(operation) index",
                "$0 \(operation) 0",
                "keyValues?.count ?? 0 \(operation) 0",
                "string \(operation) string.lowercased()",
                """
                let num: Int? = 0
                _ = num != nil && num \(operation) num?.byteSwapped
                """
            ]
        } + [
            "func evaluate(_ mode: CommandMode) -> Result<AutoCorrectOptions, CommandantError<CommandantError<()>>>",
            "let array = Array<Array<Int>>()"
        ],
        triggeringExamples: operators.flatMap { operation in
            [
                "↓1 \(operation) 1",
                "↓foo \(operation) foo",
                "↓foo.aProperty \(operation) foo.aProperty",
                "↓self.aProperty \(operation) self.aProperty",
                "↓$0 \(operation) $0"
            ]
        }
    )

    public func validate(file: File) -> [StyleViolation] {
        let operators = type(of: self).operators.joined(separator: "|")
        let pattern = """
        (?<!\\.|\\$)(?:\\s|\\b|\\A)([\\$A-Za-z0-9_\\.]+)\\s*(\(operators))\\s*\\1\\b(?!\\s*(\\.|\\>|\\<|\\?))
        """
        let syntaxKinds = SyntaxKind.commentKinds
        let excludingPattern = "\\?\\?\\s*" + pattern

        let range = NSRange(location: 0, length: file.contents.utf16.count)
        let exclusionRanges = regex(excludingPattern).matches(in: file.contents, options: [],
                                                              range: range).map { $0.range }

        return file.matchesAndTokens(matching: pattern)
            .filter { result, _ in
                let range = result.range(at: 1)
                return !range.intersects(exclusionRanges)
            }
            .filter { result, tokens in
                let contents = file.contents.bridge()
                let range = result.range(at: 1)
                guard let byteRange = contents.NSRangeToByteRange(start: range.location,
                                                                  length: range.length) else {
                    return false
                }

                return tokens
                    .filter { $0.offset >= byteRange.location }
                    .kinds
                    .filter(syntaxKinds.contains).isEmpty
            }
            .compactMap { result, tokens in
                return (result, tokens.kinds)
            }
            .compactMap { result, syntaxKinds -> StyleViolation? in
                guard Set(syntaxKinds) != [.typeidentifier] else {
                    return nil
                }

                let range = result.range(at: 1)
                let operatorRange = result.range(at: 2)
                let contents = file.contents.bridge()

                guard let byteRange = contents.NSRangeToByteRange(start: operatorRange.location,
                                                                  length: operatorRange.length),
                    file.syntaxMap.kinds(inByteRange: byteRange).isEmpty else {
                        return nil
                }

                return StyleViolation(ruleDescription: type(of: self).description,
                                      severity: configuration.severity,
                                      location: Location(file: file, characterOffset: range.location))
            }
    }
}
