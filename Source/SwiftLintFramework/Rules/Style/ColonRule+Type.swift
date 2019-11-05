import Foundation
import SourceKittenFramework

internal typealias ColonRuleMatchTokens = ([NSRange], [SwiftLintSyntaxToken])

internal extension ColonRule {
    var pattern: String {
        // If flexible_right_spacing is true, match only 0 whitespaces.
        // If flexible_right_spacing is false or omitted, match 0 or 2+ whitespaces.
        let spacingRegex = configuration.flexibleRightSpacing ? "(?:\\s{0})" : "(?:\\s{0}|\\s{2,})"

        return "(\\w)" +                // Capture an identifier.
            "(<[\\w\\s:\\.,]+>)?" +     // Capture a generic parameter clause (optional).
            "(?:" +                     // Start group
            "\\s+" +                    // followed by whitespace
            ":" +                       // to the left of a colon
            "\\s*" +                    // followed by any amount of whitespace.
            "|" +                       // or
            ":" +                       // immediately followed by a colon
            spacingRegex +              // followed by right spacing regex
            ")" +                       // end group
            "(" +                       // Capture a type identifier
            "[\\[|\\(]*" +              // which may begin with a series of nested parenthesis or brackets
            "\\S)"                      // lazily to the first non-whitespace character.
    }

    func typeColonViolationRanges(in file: SwiftLintFile, matching pattern: String) -> [NSRange] {
        let validator = ColonRuleValidator(file: file, pattern: pattern)
        return validator.typeColonViolationRanges()
    }
}

private extension SwiftLintFile {
    func isTypeLike(token: SwiftLintSyntaxToken) -> Bool {
        guard let text = contents(for: token),
            let firstLetter = text.unicodeScalars.first else {
                return false
        }

        return CharacterSet.uppercaseLetters.contains(firstLetter)
    }
}

internal class ColonRuleValidator {
    private let file: SwiftLintFile
    private let pattern: String
    private let outsideRangesPairer: OutsideRangesPair

    init(file: SwiftLintFile, pattern: String) {
        self.file = file
        self.pattern = pattern
        self.outsideRangesPairer = OutsideRangesPair()
    }

    func typeColonViolationRanges() -> [NSRange] {
        let contents = file.stringView
        let matchesAndTokens = violationMatchTokens()
        return Array(matchesAndTokens.joined())
            .compactMap { ranges, syntaxTokens in
                let firstSyntaxTokenByteRange = ByteRange(location: syntaxTokens[0].offset, length: 0)
                let identifierRange = contents.byteRangeToNSRange(firstSyntaxTokenByteRange)
                return identifierRange.map { NSUnionRange($0, ranges[0]) }
            }
    }

    private func violationMatchTokens(range: NSRange? = nil) -> [[ColonRuleMatchTokens]] {
        return SwiftLintFile.matchesAndTokens(matching: pattern, file: file, range: range)
            .compactMap({ matchTokens -> [ColonRuleMatchTokens] in
                let (match, syntaxTokens) = matchTokens
                var ranges = [NSRange]()
                if match.numberOfRanges > 0 {
                    for index in 1...match.numberOfRanges {
                        ranges.append(match.range(at: index - 1))
                    }
                }

                return fillValidResults(ranges: ranges,
                                        syntaxTokens: syntaxTokens,
                                        result: [])
            })
    }

    private func validGenericDefinitionMatch(ranges: [NSRange],
                                             syntaxTokens: [SwiftLintSyntaxToken]) -> ColonRuleMatchTokens? {
        let tokens = [syntaxTokens.first, syntaxTokens.last].compactMap { $0 }
        if isValidMatch(syntaxTokens: tokens) {
            return (ranges, tokens)
        }
        return nil
    }

    private func fillValidGenericDefinitions(ranges: [NSRange],
                                             syntaxTokens: [SwiftLintSyntaxToken],
                                             result: [ColonRuleMatchTokens]) -> [ColonRuleMatchTokens] {
        var returnResult = [ColonRuleMatchTokens]()
        if ranges[2].length > 0 && syntaxTokens.count > 2 { // captured a generic definition
            if let genericMatch = validGenericDefinitionMatch(ranges: ranges, syntaxTokens: syntaxTokens) {
                returnResult.append(genericMatch)
                // filter ranges excluding already filtered
                let ranges = genericMatch.0
                let filteredGenericRanges = ranges.filter({ $0 != ranges.first && $0 != ranges.last })
                if let pair = outsideRangesPairer.pair(ranges: filteredGenericRanges) {
                    let internalLength = pair.last.location - pair.first.location + pair.last.length
                    let internalRange = NSRange(location: pair.first.location, length: internalLength)
                    let internalViolationTokens = violationMatchTokens(range: internalRange)
                    returnResult.append(contentsOf: internalViolationTokens.joined())
                }
            }
        }
        return returnResult
    }

    private func fillValidResults(ranges: [NSRange],
                                  syntaxTokens: [SwiftLintSyntaxToken],
                                  result: [ColonRuleMatchTokens]) -> [ColonRuleMatchTokens] {
        let resultGeneric = fillValidGenericDefinitions(ranges: ranges,
                                                        syntaxTokens: syntaxTokens,
                                                        result: result)
        var resultAppend = result + resultGeneric

        if resultGeneric.isEmpty && isValidMatch(syntaxTokens: syntaxTokens) {
            resultAppend.append((ranges, syntaxTokens))
        }
        return resultAppend
    }

    private func isValidMatch(syntaxTokens: [SwiftLintSyntaxToken]) -> Bool {
        let syntaxKinds = syntaxTokens.kinds

        guard syntaxKinds.count == 2 else {
            return false
        }

        var validKinds: Bool
        switch (syntaxKinds[0], syntaxKinds[1]) {
        case (.identifier, .typeidentifier),
             (.typeidentifier, .typeidentifier):
            validKinds = true
        case (.identifier, .keyword),
             (.typeidentifier, .keyword):
            validKinds = file.isTypeLike(token: syntaxTokens[1])
            // Exclude explicit "Self" type because of static variables
            if syntaxKinds[0] == .identifier,
                file.contents(for: syntaxTokens[1]) == "Self" {
                validKinds = false
            }
        case (.keyword, .typeidentifier):
            validKinds = file.isTypeLike(token: syntaxTokens[0])
        default:
            validKinds = false
        }

        guard validKinds else {
            return false
        }

        return Set(syntaxKinds).isDisjoint(with: SyntaxKind.commentAndStringKinds)
    }
}
