import Foundation
import SourceKittenFramework

public struct IdenticalOperandsRule: ConfigurationProviderRule, OptInRule {
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
                Example("1 \(operation) 2"),
                Example("foo \(operation) bar"),
                Example("prefixedFoo \(operation) foo"),
                Example("foo.aProperty \(operation) foo.anotherProperty"),
                Example("self.aProperty \(operation) self.anotherProperty"),
                Example("\"1 \(operation) 1\""),
                Example("self.aProperty \(operation) aProperty"),
                Example("lhs.aProperty \(operation) rhs.aProperty"),
                Example("lhs.identifier \(operation) rhs.identifier"),
                Example("i \(operation) index"),
                Example("$0 \(operation) 0"),
                Example("keyValues?.count ?? 0 \(operation) 0"),
                Example("string \(operation) string.lowercased()"),
                Example("""
                let num: Int? = 0
                _ = num != nil && num \(operation) num?.byteSwapped
                """),
                Example("num \(operation) num!.byteSwapped")
            ]
        } + [
            // swiftlint:disable:next line_length
            Example("func evaluate(_ mode: CommandMode) -> Result<AutoCorrectOptions, CommandantError<CommandantError<()>>>"),
            Example("let array = Array<Array<Int>>()"),
            Example("guard Set(identifiers).count != identifiers.count else { return }"),
            Example(#"expect("foo") == "foo""#),
            Example("type(of: model).cachePrefix == cachePrefix"),
            Example("histogram[156].0 == 0x003B8D96 && histogram[156].1 == 1")
        ],
        triggeringExamples: operators.flatMap { operation in
            [
                Example("↓1 \(operation) 1"),
                Example("↓foo \(operation) foo"),
                Example("↓foo.aProperty \(operation) foo.aProperty"),
                Example("↓self.aProperty \(operation) self.aProperty"),
                Example("↓$0 \(operation) $0"),
                Example("↓a?.b \(operation) a?.b"),
                Example("if (↓elem \(operation) elem) {}"),
                Example("XCTAssertTrue(↓s3 \(operation) s3)"),
                Example("if let tab = tabManager.selectedTab, ↓tab.webView \(operation) tab.webView")
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
        let operators = Self.operators.joined(separator: "|")
        return
            file.matchesAndTokens(matching: "\\s(" + operators + ")\\s")
                .filter { _, tokens in tokens.isEmpty }
                .compactMap { matchResult, _ in violationRangeFrom(match: matchResult, in: file) }
                .map { range in
                    return StyleViolation(ruleDescription: Self.description,
                                          severity: configuration.severity,
                                          location: Location(file: file, characterOffset: range.location))
                }
    }

    private func violationRangeFrom(match: NSTextCheckingResult, in file: SwiftLintFile) -> NSRange? {
        let contents = file.stringView
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
        let operatorString = contents.substring(with: operatorRange)
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

        let violationRange = file.stringView.byteRangeToNSRange(leftmostToken.range)
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

                guard file.stringView.isDotOrOptionalChainingBetweenTokens(prevToken, leftMostToken) else { break }

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

                guard file.stringView.isDotOrOptionalChainingBetweenTokens(rightMostToken, nextToken) else { break }

                rightTokens.append(nextToken)
                currentIndex += 1
                rightMostToken = nextToken
            }

            return (Operand(index: leftTokenIndex - leftTokens.count + 1, tokens: leftTokens),
                    Operand(index: rightTokenIndex, tokens: rightTokens))
    }
}

private extension StringView {
    func subStringWithSyntaxToken(_ syntaxToken: SwiftLintSyntaxToken) -> String? {
        return substringWithByteRange(syntaxToken.range)
    }

    func subStringBetweenTokens(_ startToken: SwiftLintSyntaxToken, _ endToken: SwiftLintSyntaxToken) -> String? {
        let byteRange = ByteRange(location: startToken.range.upperBound,
                                  length: endToken.offset - startToken.range.upperBound)
        return substringWithByteRange(byteRange)
    }

    func isDotOrOptionalChainingBetweenTokens(_ startToken: SwiftLintSyntaxToken,
                                              _ endToken: SwiftLintSyntaxToken) -> Bool {
        return isRegexBetweenTokens(startToken, #"[\?!]?\."#, endToken)
    }

    func isWhiteSpaceBetweenTokens(_ startToken: SwiftLintSyntaxToken,
                                   _ endToken: SwiftLintSyntaxToken) -> Bool {
        guard let betweenTokens = subStringBetweenTokens(startToken, endToken) else { return false }
        let range = betweenTokens.fullNSRange
        return regex(#"^[\s\(,]*$"#).matches(in: betweenTokens, options: [], range: range).isNotEmpty
    }

    func isRegexBetweenTokens(_ startToken: SwiftLintSyntaxToken, _ regexString: String,
                              _ endToken: SwiftLintSyntaxToken) -> Bool {
        guard let betweenTokens = subStringBetweenTokens(startToken, endToken) else { return false }

        let range = betweenTokens.fullNSRange
        return regex("^\\s*\(regexString)\\s*$").matches(in: betweenTokens, options: [], range: range).isNotEmpty
    }
}
