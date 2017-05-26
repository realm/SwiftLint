//
//  OpeningBraceRule.swift
//  SwiftLint
//
//  Created by Alex Culeva on 10/21/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private let whitespaceAndNewlineCharacterSet = CharacterSet.whitespacesAndNewlines

extension File {
    fileprivate func violatingOpeningBraceRanges() -> [NSRange] {
        return match(pattern: "((?:[^( ]|[\\s(][\\s]+)\\{)",
                     excludingSyntaxKinds: SyntaxKind.commentAndStringKinds(),
                     excludingPattern: "(?:if|guard|while)\\n[^\\{]+?[\\s\\t\\n]\\{")
    }
}

public struct OpeningBraceRule: CorrectableRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "opening_brace",
        name: "Opening Brace Spacing",
        description: "Opening braces should be preceded by a single space and on the same line " +
                     "as the declaration.",
        nonTriggeringExamples: [
            "func abc() {\n}",
            "[].map() { $0 }",
            "[].map({ })",
            "if let a = b { }",
            "while a == b { }",
            "guard let a = b else { }",
            "if\n\tlet a = b,\n\tlet c = d\n\twhere a == c\n{ }",
            "while\n\tlet a = b,\n\tlet c = d\n\twhere a == c\n{ }",
            "guard\n\tlet a = b,\n\tlet c = d\n\twhere a == c else\n{ }"
        ],
        triggeringExamples: [
            "func abc(↓){\n}",
            "func abc()↓\n\t{ }",
            "[].map(↓){ $0 }",
            "[].map↓( { } )",
            "if let a = b{ }",
            "while a == b{ }",
            "guard let a = b else{ }",
            "if\n\tlet a = b,\n\tlet c = d\n\twhere a == c{ }",
            "while\n\tlet a = b,\n\tlet c = d\n\twhere a == c{ }",
            "guard\n\tlet a = b,\n\tlet c = d\n\twhere a == c else{ }"
        ],
        corrections: [
            "struct Rule{}\n": "struct Rule {}\n",
            "struct Rule\n{\n}\n": "struct Rule {\n}\n",
            "struct Rule\n\n\t{\n}\n": "struct Rule {\n}\n",
            "struct Parent {\n\tstruct Child\n\t{\n\t\tlet foo: Int\n\t}\n}\n":
                "struct Parent {\n\tstruct Child {\n\t\tlet foo: Int\n\t}\n}\n",
            "[].map(){ $0 }\n": "[].map() { $0 }\n",
            "[].map( { })\n": "[].map({ })\n",
            "if a == b{ }\n": "if a == b { }\n",
            "if\n\tlet a = b,\n\tlet c = d{ }\n": "if\n\tlet a = b,\n\tlet c = d { }\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return file.violatingOpeningBraceRanges().map {
            StyleViolation(ruleDescription: type(of: self).description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func correct(file: File) -> [Correction] {
        let violatingRanges = file.ruleEnabled(violatingRanges: file.violatingOpeningBraceRanges(), for: self)
        var correctedContents = file.contents
        var adjustedLocations = [Int]()

        for violatingRange in violatingRanges.reversed() {
            let (contents, adjustedRange) = correct(contents: correctedContents, violatingRange: violatingRange)

            correctedContents = contents
            if let adjustedRange = adjustedRange {
                adjustedLocations.insert(adjustedRange.location, at: 0)
            }
        }

        file.write(correctedContents)

        return adjustedLocations.map {
            Correction(ruleDescription: type(of: self).description,
                       location: Location(file: file, characterOffset: $0))
        }
    }

    private func correct(contents: String,
                         violatingRange: NSRange) -> (correctedContents: String, adjustedRange: NSRange?) {
        guard let indexRange = contents.nsrangeToIndexRange(violatingRange) else {
            return (contents, nil)
        }
        let capturedString = String(contents[indexRange])
        var adjustedRange = violatingRange
        var correctString = " {"

        // "struct Command{" has violating string = "d{", so ignore first "d"
        if capturedString.characters.count == 2 &&
            capturedString.rangeOfCharacter(from: whitespaceAndNewlineCharacterSet) == nil {
            adjustedRange = NSRange(
                location: violatingRange.location + 1,
                length: violatingRange.length - 1
            )
        }

        // "[].map( { } )" has violating string = "( {",
        // so ignore first "(" and use "{" as correction string instead
        if capturedString.hasPrefix("(") {
            adjustedRange = NSRange(
                location: violatingRange.location + 1,
                length: violatingRange.length - 1
            )
            correctString = "{"
        }

        if let indexRange = contents.nsrangeToIndexRange(adjustedRange) {
            let correctedContents = contents
                .replacingCharacters(in: indexRange, with: correctString)
            return (correctedContents, adjustedRange)
        } else {
            return (contents, nil)
        }
    }
}
