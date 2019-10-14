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
                "↓$0 \(operation) $0",
                "XCTAssertTrue(↓s1 \(operation) s2)"
            ]
        }
    )

    public func validate(file: File) -> [StyleViolation] {
        let operators = type(of: self).operators.joined(separator: "|")

        let findOperators = """
        (?:\\s*)(\(operators))\\s*([\\$A-Za-z0-9_\\.]+)(?!\\s*(\\.|\\>|\\<|\\?))
        """

        struct IdenticalMatch {
            let firstIdentifierRange: NSRange
            let operatorRange: NSRange
            let secondIndentifierRange: NSRange
            let fullRange: NSRange
        }

        return file.matchesAndTokens(matching: findOperators)
            .compactMap { result, tokens -> (IdenticalMatch, [SyntaxToken])? in
                let secondIdentifierRange = result.range(at: 2)
                let identifierLength = secondIdentifierRange.length
                guard let secondIdentifier = file.contents.validSubstring(range: secondIdentifierRange) else { return nil }

                // Check what was before
                let firstIdentifierLocation = result.range.location - identifierLength
                guard firstIdentifierLocation >= 0 else {
                    // Not enough place to match firs Identifier
                    return nil
                }

                // Skip if we cannot convert range to nstrange
                let firstIdentifierRange = NSRange(location: firstIdentifierLocation, length: identifierLength)
                guard let firstIdentifier = file.contents.validSubstring(range: firstIdentifierRange) else { return nil }

                guard firstIdentifier == secondIdentifier else { return nil }

                // make sure that previous one is a word boundary
                if firstIdentifierLocation != 0 {
                    guard let previousCharacter = file.contents.validSubstring(from: firstIdentifierLocation - 1, length: 1) else { return nil }
                    guard [" ", "\n", "\t", "\r", "(", "{", "[" ].contains(previousCharacter) else { return nil }
                }

                // Make sure that we doesn't have ??
                // We'll skip multiple whitespaces before ?? for now and let's see how it performs
                if firstIdentifierLocation > 3 {
                    guard let previousCharacters = file.contents.validSubstring(from: firstIdentifierLocation - 3, length: 2) else { return nil }
                    guard previousCharacters != "??" else { return nil }
                }
                let fullMatchRange = NSRange(location: firstIdentifierLocation, length: identifierLength + result.range.length)

                let identicalMatch = IdenticalMatch(
                    firstIdentifierRange: firstIdentifierRange,
                    operatorRange: result.range(at: 1),
                    secondIndentifierRange: secondIdentifierRange,
                    fullRange: fullMatchRange
                )
                return (identicalMatch, tokens)
            }

            // Skip comments
            .filter { result, _ in
                let contents = file.contents.bridge()
                guard let byteRange = contents.NSRangeToByteRange(start: result.operatorRange.location,
                                                                  length: result.operatorRange.length),
                    file.syntaxMap.kinds(inByteRange: byteRange).isEmpty else {
                        return false
                }
                return true
            }

             .compactMap { result, syntaxKinds -> StyleViolation? in
                guard Set(syntaxKinds.kinds) != [.typeidentifier] else {
                    return nil
                }
                return StyleViolation(ruleDescription: type(of: self).description,
                                      severity: configuration.severity,
                                      location: Location(file: file, characterOffset: result.fullRange.location))
             }
    }
}

private extension String {
    internal func validSubstring(from: Int, length: Int) -> String? {
        return validSubstring(range: NSRange(location: from, length: length))
    }

    internal func validSubstring(range: NSRange) -> String? {
        guard let indexRange = nsrangeToIndexRange(range) else { return nil }
        return String(self[indexRange])
    }
}
