//
//  Comma.swift
//  SwiftLint
//
//  Created by Alex Culeva on 10/22/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct CommaRule: CorrectableRule {
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
            "enum a { case a  ,b }\n": "enum a { case a, b }\n"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        let pattern = "(\\,[^\\s])|(\\s\\,)"
        let excludingKinds = SyntaxKind.commentAndStringKinds()

        return file.matchPattern(pattern, excludingSyntaxKinds: excludingKinds).map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func correctFile(file: File) -> [Correction] {
        guard validateFile(file).count > 0 else { return [] }
        let pattern = "\\s*\\,\\s*([^\\s])"

        let description = self.dynamicType.description
        var corrections = [Correction]()
        var contents = file.contents

        let matches = file.matchPattern(pattern, withSyntaxKinds: [.Identifier])

        let regularExpression = regex(pattern)
        for range in matches.reverse() {
            contents = regularExpression.stringByReplacingMatchesInString(contents,
                options: [], range: range, withTemplate: ", $1")
            let location = Location(file: file, characterOffset: range.location)
            corrections.append(Correction(ruleDescription: description, location: location))
        }

        file.write(contents)
        return corrections
    }
}
