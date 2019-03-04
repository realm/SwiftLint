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

    func typeColonViolationRanges(in file: File, matching pattern: String) -> [NSRange] {
        let nsstring = file.contents.bridge()
        return file.matchesAndTokens(matching: pattern).filter { match, syntaxTokens in
            if match.range(at: 2).length > 0 && syntaxTokens.count > 2 { // captured a generic definition
                let tokens = [syntaxTokens.first, syntaxTokens.last].compactMap { $0 }
                return isValidMatch(syntaxTokens: tokens, file: file)
            }

            return isValidMatch(syntaxTokens: syntaxTokens, file: file)
        }.compactMap { match, syntaxTokens in
            let identifierRange = nsstring
                .byteRangeToNSRange(start: syntaxTokens[0].offset, length: 0)
            return identifierRange.map { NSUnionRange($0, match.range) }
        }
    }

    private func isValidMatch(syntaxTokens: [SyntaxToken], file: File) -> Bool {
        let syntaxKinds = syntaxTokens.kinds

        guard syntaxKinds.count == 2 else {
            return false
        }

        let validKinds: Bool
        switch (syntaxKinds[0], syntaxKinds[1]) {
        case (.identifier, .typeidentifier),
             (.typeidentifier, .typeidentifier):
            validKinds = true
        case (.identifier, .keyword),
             (.typeidentifier, .keyword):
            validKinds = file.isTypeLike(token: syntaxTokens[1])
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

private extension File {
    func isTypeLike(token: SyntaxToken) -> Bool {
        let nsstring = contents.bridge()
        guard let text = nsstring.substringWithByteRange(start: token.offset, length: token.length),
            let firstLetter = text.unicodeScalars.first else {
                return false
        }

        return CharacterSet.uppercaseLetters.contains(firstLetter)
    }
}
