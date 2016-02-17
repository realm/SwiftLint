//
//  Comma.swift
//  SwiftLint
//
//  Created by Alex Culeva on 10/22/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct CommaRule: CorrectableRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.Warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "comma",
        name: "Comma Spacing",
        description: "There should be no space before and one after any comma.",
        nonTriggeringExamples: [
            "func abc(a: String, b: String) { }",
            "abc(a: \"string\", b: \"string\"",
            "enum a { case a, b, c }"
        ],
        triggeringExamples: [
            "func abc(a: String↓ ,b: String) { }",
            "abc(a: \"string\"↓,b: \"string\"",
            "enum a { case a↓ ,b }"
        ],
        corrections: [
            "func abc(a: String,b: String) {}\n": "func abc(a: String, b: String) {}\n",
            "abc(a: \"string\",b: \"string\"\n": "abc(a: \"string\", b: \"string\"\n",
            "abc(a: \"string\"  ,  b: \"string\"\n": "abc(a: \"string\", b: \"string\"\n",
            "enum a { case a  ,b }\n": "enum a { case a, b }\n",
            "let a = [1,1]\nlet b = 1\nf(1, b)\n": "let a = [1, 1]\nlet b = 1\nf(1, b)\n",
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        return violationRangesInFile(file).map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func correctFile(file: File) -> [Correction] {
        let matches = violationRangesInFile(file)
        if matches.isEmpty { return [] }

        var contents = file.contents as NSString
        let description = self.dynamicType.description
        var corrections = [Correction]()
        for range in matches.reverse() {
            contents = contents.stringByReplacingCharactersInRange(range, withString: ", ")
            let location = Location(file: file, characterOffset: range.location)
            corrections.append(Correction(ruleDescription: description, location: location))
        }

        file.write(contents as String)
        return corrections
    }

    // captures spaces and comma only
    private static let pattern =
        "\\S" +                // not whitespace
        "(" +                  // start capure
        "\\s+" +               // followed by whitespace
        "," +                  // to the left of a comma
        "\\s*" +               // followed by any amount of whitespace.
        "|" +                  // or
        "," +                  // immediately followed by a comma
        "(?:\\s{0}|\\s{2,})" + // followed by 0 or 2+ whitespace characters.
        ")" +                  // end capture
        "\\S"                  // not whitespace

    // swiftlint:disable:next force_try
    private static let regularExpression = try! NSRegularExpression(pattern: pattern, options: [])
    private static let excludingSyntaxKinds = SyntaxKind.commentAndStringKinds().map { $0.rawValue }

    private func violationRangesInFile(file: File) -> [NSRange] {
        let contents = file.contents
        let range = NSRange(location: 0, length: contents.utf16.count)
        let tokens = file.syntaxMap.tokens
        return CommaRule.regularExpression
            .matchesInString(contents, options: [], range: range)
            .flatMap { match -> NSRange? in
                if match.numberOfRanges != 2 { return nil }

                // use captured range
                let range1 = match.rangeAtIndex(1)
                guard let matchByteRange = contents
                    .NSRangeToByteRange(start: range1.location, length: range1.length)
                    else { return nil }

                // captured range won't match tokens if it is not comment neither string.
                let tokensInRange = tokens.filter { token in
                    let tokenByteRange = NSRange(location: token.offset, length: token.length)
                    return NSIntersectionRange(matchByteRange, tokenByteRange).length > 0
                    }.filter { CommaRule.excludingSyntaxKinds.contains($0.type) }

                // If not empty, captured range is comment or string
                if !tokensInRange.isEmpty {
                    return nil
                }
                // return captured range
                return range1
        }
    }
}
