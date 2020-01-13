import Foundation
import SourceKittenFramework

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
        let contents = file.stringView
        return file.matchesAndTokens(matching: pattern).filter { match, syntaxTokens in
            if match.range(at: 2).length > 0 && syntaxTokens.count > 2 { // captured a generic definition
                let tokens = [syntaxTokens.first, syntaxTokens.last].compactMap { $0 }
                return isValidMatch(syntaxTokens: tokens, file: file)
            }

            return isValidMatch(syntaxTokens: syntaxTokens, file: file)
        }.compactMap { match, syntaxTokens in
            let firstSyntaxTokenByteRange = ByteRange(location: syntaxTokens[0].offset, length: 0)
            let identifierRange = contents.byteRangeToNSRange(firstSyntaxTokenByteRange)
            return identifierRange.map { NSUnionRange($0, match.range) }
        }
    }

    private func isValidMatch(syntaxTokens: [SwiftLintSyntaxToken], file: SwiftLintFile) -> Bool {
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

private extension SwiftLintFile {
    func isTypeLike(token: SwiftLintSyntaxToken) -> Bool {
        guard let text = contents(for: token),
            let firstLetter = text.unicodeScalars.first else {
                return false
        }

        return CharacterSet.uppercaseLetters.contains(firstLetter)
    }
}
