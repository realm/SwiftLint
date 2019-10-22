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
                "XCTAssertTrue(↓s1 \(operation) s1)"
            ]
        }
    )

    private struct OperandsMatch {
        let operatorRange: NSRange
        let fullRange: NSRange
    }

    public func validate(file: File) -> [StyleViolation] {
        let operators = type(of: self).operators.joined(separator: "|")

        let findOperators = """
        (?:\\s*)(\(operators))\\s*([\\$A-Za-z0-9_\\.]+)(?!\\s*(\\.|\\>|\\<|\\?))
        """

        return file.matchesAndTokens(matching: findOperators)
            .compactMap { result, tokens -> (OperandsMatch, [SyntaxToken])? in
                let rightOperandRange = result.range(at: 2)
                let operandLength = rightOperandRange.length
                guard let rightOperand = file.contents.validSubstring(range: rightOperandRange) else { return nil }

                // Check what was before
                let leftOperandLocation = result.range.location - operandLength
                guard leftOperandLocation >= 0 else {
                    // Not enough place to match firs Identifier
                    return nil
                }

                // Skip if we cannot convert range to nstrange
                let leftOperandRange = NSRange(location: leftOperandLocation, length: operandLength)
                guard let leftOperand = file.contents.validSubstring(range: leftOperandRange) else { return nil }

                guard leftOperand == rightOperand else { return nil }

                // Check if previous identifier is a word boundary
                guard isWordBoundary(in: file, before: leftOperandLocation) else { return nil }

                // Make sure that we doesn't have ??
                guard !isNilCoalesingOperator(in: file, before: leftOperandLocation) else { return nil }

                let fullMatchRange = NSRange(location: leftOperandLocation, length: operandLength + result.range.length)

                let identicalMatch = OperandsMatch(
                    operatorRange: result.range(at: 1),
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

    private func isWordBoundary(in file: File, before index: Int) -> Bool {
        guard index != 0 else { return true }
        guard let previousCharacter = file.contents.validSubstring(from: index - 1, length: 1) else { return false }
        guard [" ", "\n", "\t", "\r", "(", "{", "[" ].contains(previousCharacter) else { return false }
        return true
    }

    private func isNilCoalesingOperator(in file: File, before index: Int) -> Bool {
        // We'll skip multiple whitespaces before ?? for now and let's see how it performs
        guard index > 3 else { return false }
        guard let previousCharacters = file.contents.validSubstring(from: index - 3, length: 2) else { return false }
        return previousCharacters == "??"
    }
}

private extension String {
    func validSubstring(from: Int, length: Int) -> String? {
        return validSubstring(range: NSRange(location: from, length: length))
    }

    func validSubstring(range: NSRange) -> String? {
        guard let indexRange = nsrangeToIndexRange(range) else { return nil }
        return String(self[indexRange])
    }
}
