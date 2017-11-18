//
//  ColonRule+Type.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 09/13/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

internal extension ColonRule {

    var pattern: String {
        // If flexible_right_spacing is true, match only 0 whitespaces.
        // If flexible_right_spacing is false or omitted, match 0 or 2+ whitespaces.
        let spacingRegex = configuration.flexibleRightSpacing ? "(?:\\s{0})" : "(?:\\s{0}|\\s{2,})"

        return "(\\w)" +       // Capture an identifier
            "(?:" +         // start group
            "\\s+" +        // followed by whitespace
            ":" +           // to the left of a colon
            "\\s*" +        // followed by any amount of whitespace.
            "|" +           // or
            ":" +           // immediately followed by a colon
            spacingRegex +  // followed by right spacing regex
            ")" +           // end group
            "(" +           // Capture a type identifier
            "[\\[|\\(]*" +  // which may begin with a series of nested parenthesis or brackets
        "\\S)"          // lazily to the first non-whitespace character.
    }

    func typeColonViolationRanges(in file: File, matching pattern: String) -> [NSRange] {
        let nsstring = file.contents.bridge()
        let commentAndStringKindsSet = SyntaxKind.commentAndStringKinds
        return file.rangesAndTokens(matching: pattern).filter { _, syntaxTokens in
            let syntaxKinds = syntaxTokens.flatMap { SyntaxKind(rawValue: $0.type) }

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

            return Set(syntaxKinds).isDisjoint(with: commentAndStringKindsSet)
        }.flatMap { range, syntaxTokens in
            let identifierRange = nsstring
                .byteRangeToNSRange(start: syntaxTokens[0].offset, length: 0)
            return identifierRange.map { NSUnionRange($0, range) }
        }
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
