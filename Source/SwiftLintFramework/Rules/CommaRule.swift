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
            "enum a { case a, b, c }",
            "func abc(\n  a: String,  // comment\n  bcd: String // comment\n) {\n}\n",
            "func abc(\n  a: String,\n  bcd: String\n) {\n}\n",
        ],
        triggeringExamples: [
            "func abc(a: String↓ ,b: String) { }",
            "abc(a: \"string\"↓,b: \"string\"",
            "enum a { case a↓ ,b }",
            "let result = plus(\n    first: 3↓ , // #683\n    second: 4\n)\n",
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
    // http://userguide.icu-project.org/strings/regexp
    private static let pattern =
        "\\S" +                // not whitespace
        "(" +                  // start first capure
        "\\s+" +               // followed by whitespace
        "," +                  // to the left of a comma
        "[\\t\\p{Z}]*" +       // followed by any amount of tab or space.
        "|" +                  // or
        "," +                  // immediately followed by a comma
        "(?:[\\t\\p{Z}]{0}|" + // followed by 0
        "[\\t\\p{Z}]{2,})" +   // or 2+ tab or space characters.
        ")" +                  // end capture
        "(\\S)"                // second capture is not whitespace.

    // swiftlint:disable:next force_try
    private static let regularExpression = try! NSRegularExpression(pattern: pattern, options: [])
    private static let excludingSyntaxKindsForFirstCapture = SyntaxKind.commentAndStringKinds()
        .map { $0.rawValue }
    private static let excludingSyntaxKindsForSecondCapture = SyntaxKind.commentKinds()
        .map { $0.rawValue }

    private func violationRangesInFile(file: File) -> [NSRange] {
        let contents = file.contents
        let range = NSRange(location: 0, length: contents.utf16.count)
        let syntaxMap = file.syntaxMap
        return CommaRule.regularExpression
            .matchesInString(contents, options: [], range: range)
            .flatMap { match -> NSRange? in
                if match.numberOfRanges != 3 { return nil }

                // check first captured range
                let firstRange = match.rangeAtIndex(1)
                guard let matchByteFirstRange = contents
                    .NSRangeToByteRange(start: firstRange.location, length: firstRange.length)
                    else { return nil }

                // first captured range won't match tokens if it is not comment neither string
                let tokensInFirstRange = syntaxMap.tokensIn(matchByteFirstRange)
                    .filter { CommaRule.excludingSyntaxKindsForFirstCapture.contains($0.type) }

                // If not empty, first captured range is comment or string
                if !tokensInFirstRange.isEmpty {
                    return nil
                }

                // If the first range does not start with comma, it already violates this rule
                // no matter what is contained in the second range.
                if !(contents as NSString).substringWithRange(firstRange).hasPrefix(",") {
                    return firstRange
                }

                // check second captured range
                let secondRange = match.rangeAtIndex(2)
                guard let matchByteSecondRange = contents
                    .NSRangeToByteRange(start: secondRange.location, length: secondRange.length)
                    else { return nil }

                // second captured range won't match tokens if it is not comment
                let tokensInSecondRange = syntaxMap.tokensIn(matchByteSecondRange)
                    .filter { CommaRule.excludingSyntaxKindsForSecondCapture.contains($0.type) }

                // If not empty, second captured range is comment
                if !tokensInSecondRange.isEmpty {
                    return nil
                }

                // return first captured range
                return firstRange
        }
    }
}
