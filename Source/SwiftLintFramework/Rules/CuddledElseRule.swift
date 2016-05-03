//
//  CuddledElseRule.swift
//  SwiftLint
//
//  Created by Michael Skiba on 5/3/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct CuddledElseRule: ConfigurationProviderRule, OptInRule {

    public var configuration = SeverityConfiguration(.Warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "cuddled_else",
        name: "Cuddled else",
        description: "Else and catch should on the next line, with equal indentation to the " +
            "previous declaration.",
        nonTriggeringExamples: [
            "  }\n  else if {",
            "    }\n    else {",
            "  }\n  catch {",
            "  }\n\n  catch {",
            "\n\n  }\n  catch {",
            "\"}\nelse{\"",
            "struct A { let catchphrase: Int }\nlet a = A(\n catchphrase: 0\n)",
            "struct A { let `catch`: Int }\nlet a = A(\n `catch`: 0\n)"
        ],
        triggeringExamples: [
            "↓  }else if {",
            "↓}\n  else {",
            "↓  }\ncatch {",
            "↓}\n\t  catch {"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        return violationRangesInFile(file, withPattern: CuddledElseRule.pattern).flatMap { range in
            return StyleViolation(ruleDescription: self.dynamicType.description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: range.location))
        }
    }

    // MARK: - Private

    // match literal '}'
    // preceded by whitespace (or nothing)
    // followed by 1) nothing, 2) two+ whitespace/newlines or 3) newlines or tabs
    // followed by newline and the same amount of whitespace then 'else' or 'catch' literals
    private static let pattern = "([ \t]*)\\}(\\n+)?([ \t]*)\\b(else|catch)\\b"
    private static let regularExpression = (try? NSRegularExpression(pattern: pattern, options: []))
        ?? NSRegularExpression()

    private func violationRangesInFile(file: File, withPattern pattern: String) -> [NSRange] {
        let contents = file.contents
        let range = NSRange(location: 0, length: contents.utf16.count)
        let syntaxMap = file.syntaxMap
        let matches = CuddledElseRule.regularExpression.matchesInString(contents,
                                                                        options: [],
                                                                        range: range)
        let validMatches = matches.flatMap { match -> NSRange? in
            if match.numberOfRanges != 5 {
                return match.range
            }
            if match.rangeAtIndex(2).length == 0 {
                return match.range
            }
            let range1 = match.rangeAtIndex(1)
            let range2 = match.rangeAtIndex(3)
            let whitespace1 = contents.substring(range1.location, length: range1.length)
            let whitespace2 = contents.substring(range2.location, length: range2.length)
            if whitespace1 == whitespace2 {
                return nil
            }
            return match.range
        }
        let rangesWithValidTokens = validMatches.filter { range in
            guard let matchRange = contents.NSRangeToByteRange(start: range.location,
                length: range.length) else {
                    return false
            }
            let tokens = syntaxMap.tokensIn(matchRange).flatMap { SyntaxKind(rawValue: $0.type) }
            return tokens == [.Keyword]
        }

        return rangesWithValidTokens
    }

}
