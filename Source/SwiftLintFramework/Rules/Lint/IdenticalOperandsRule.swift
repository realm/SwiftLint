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
                """,
                "num \(operation) num!.byteSwapped"
            ]
        } + [
            "func evaluate(_ mode: CommandMode) -> Result<AutoCorrectOptions, CommandantError<CommandantError<()>>>",
            "let array = Array<Array<Int>>()",
            "guard Set(identifiers).count != identifiers.count else { return }",
            #"expect("foo") == "foo""#,
            "type(of: model).cachePrefix == cachePrefix",
            "histogram[156].0 == 0x003B8D96 && histogram[156].1 == 1"
        ],
        triggeringExamples: operators.flatMap { operation in
            [
                "↓1 \(operation) 1",
                "↓foo \(operation) foo",
                "↓foo.aProperty \(operation) foo.aProperty",
                "↓self.aProperty \(operation) self.aProperty",
                "↓$0 \(operation) $0",
                "↓a?.b \(operation) a?.b",
                "if (↓elem \(operation) elem) {}",
                "XCTAssertTrue(↓s3 \(operation) s3)",
                "if let tab = tabManager.selectedTab, ↓tab.webView \(operation) tab.webView"
            ]
        }
    )

    private struct Operand {
        /// Index of first token in tokens
        let index: Int

        // tokens in this operand
        let tokens: [SwiftLintSyntaxToken]
    }

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let operators = type(of: self).operators.joined(separator: "|")
        return
            file.matchesAndTokens(matching: "\\s(" + operators + ")\\s")
                .filter { _, tokens in tokens.isEmpty }
                .compactMap { matchResult, _ in violationRangeFrom(match: matchResult, in: file) }
                .map { range in
                    return StyleViolation(ruleDescription: type(of: self).description,
                                          severity: configuration.severity,
                                          location: Location(file: file, characterOffset: range.location))
                }
    }

    private func violationRangeFrom(match: NSTextCheckingResult, in file: SwiftLintFile) -> NSRange? {
        let contents = file.linesContainer
        let operatorRange = match.range(at: 1)
        guard let operatorByteRange = contents.NSRangeToByteRange(operatorRange) else {
            return nil
        }

        let tokens = file.syntaxMap.tokens
        guard let rightTokenIndex = tokens.firstIndex(where: { $0.offset >= operatorByteRange.upperBound }),
            rightTokenIndex > 0 else {
                return nil
        }

        let (leftOperand, rightOperand) = operandsStartingFromIndexes(leftTokenIndex: rightTokenIndex - 1,
                                                                      rightTokenIndex: rightTokenIndex,
                                                                      file: file)

        guard leftOperand.tokens.count == rightOperand.tokens.count else {
            return nil
        }

        // Make sure that there's nothing but operator between tokens
        let operatorString = contents.nsString.substring(with: operatorRange)
        guard let leftToken = leftOperand.tokens.last, let rightToken = rightOperand.tokens.first else {
            return nil
        }
        guard contents.isRegexBetweenTokens(leftToken, operatorString, rightToken) else {
            return nil
        }

        // Make sure both operands have same token types
        guard leftOperand.tokens.map({ $0.value.type }) == rightOperand.tokens.map({ $0.value.type }) else {
            return nil
        }

        // Make sure that every part of the operand part is equal to previous one
        guard leftOperand.tokens.map(contents.subStringWithSyntaxToken) ==
            rightOperand.tokens.map(contents.subStringWithSyntaxToken) else {
            return nil
        }

        guard let leftmostToken = leftOperand.tokens.first else {
            return nil
        }

        if leftOperand.index != 0 {
            let previousToken = tokens[leftOperand.index - 1]

            guard contents.isWhiteSpaceBetweenTokens(previousToken, leftmostToken) else {
                return nil
            }
        }

        let violationRange = file.linesContainer.byteRangeToNSRange(start: leftmostToken.offset,
                                                              length: leftmostToken.length)
        return violationRange
    }

    private func operandsStartingFromIndexes(leftTokenIndex: Int, rightTokenIndex: Int, file: SwiftLintFile)
        -> (leftOperand: Operand, rightOperand: Operand) {
            let tokens = file.syntaxMap.tokens

            // expand to the left
            var currentIndex = leftTokenIndex
            var leftMostToken = tokens[currentIndex]
            var leftTokens = [leftMostToken]
            while currentIndex > 0 {
                let prevToken = tokens[currentIndex - 1]

                guard file.linesContainer.isDotOrOptionalChainingBetweenTokens(prevToken, leftMostToken) else { break }

                leftTokens.insert(prevToken, at: 0)
                currentIndex -= 1
                leftMostToken = prevToken
            }

            // expand to the right
            currentIndex = rightTokenIndex
            var rightMostToken = tokens[currentIndex]
            var rightTokens = [rightMostToken]
            while currentIndex < tokens.count - 1 {
                let nextToken = tokens[currentIndex + 1]

                guard file.linesContainer.isDotOrOptionalChainingBetweenTokens(rightMostToken, nextToken) else { break }

                rightTokens.append(nextToken)
                currentIndex += 1
                rightMostToken = nextToken
            }

            return (Operand(index: leftTokenIndex - leftTokens.count + 1, tokens: leftTokens),
                    Operand(index: rightTokenIndex, tokens: rightTokens))
    }
}

private extension StringLinesContainer {
//    func NSRangeToByteRange(_ range: NSRange) -> NSRange? {
//        return NSRangeToByteRange(start: range.location, length: range.length)
//    }

    func subStringWithSyntaxToken(_ syntaxToken: SwiftLintSyntaxToken) -> String? {
        return substringWithByteRange(start: syntaxToken.offset, length: syntaxToken.length)
    }

    func subStringBetweenTokens(_ startToken: SwiftLintSyntaxToken, _ endToken: SwiftLintSyntaxToken) -> String? {
        return substringWithByteRange(start: startToken.offset + startToken.length,
                                      length: endToken.offset - startToken.offset - startToken.length)
    }

    func isDotOrOptionalChainingBetweenTokens(_ startToken: SwiftLintSyntaxToken,
                                              _ endToken: SwiftLintSyntaxToken) -> Bool {
        return isRegexBetweenTokens(startToken, #"[\?!]?\."#, endToken)
    }

    func isWhiteSpaceBetweenTokens(_ startToken: SwiftLintSyntaxToken,
                                   _ endToken: SwiftLintSyntaxToken) -> Bool {
        guard let betweenTokens = subStringBetweenTokens(startToken, endToken) else { return false }
        let range = NSRange(location: 0, length: betweenTokens.utf16.count)
        return !regex(#"^[\s\(,]*$"#).matches(in: betweenTokens, options: [], range: range).isEmpty
    }

    func isRegexBetweenTokens(_ startToken: SwiftLintSyntaxToken, _ regexString: String,
                              _ endToken: SwiftLintSyntaxToken) -> Bool {
        guard let betweenTokens = subStringBetweenTokens(startToken, endToken) else { return false }

        let range = NSRange(location: 0, length: betweenTokens.utf16.count)
        return !regex("^\\s*\(regexString)\\s*$").matches(in: betweenTokens, options: [], range: range).isEmpty
    }
}
