//
//  ImplicitReturnRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 04/30/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ImplicitReturnRule: ConfigurationProviderRule, CorrectableRule, OptInRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "implicit_return",
        name: "Implicit Return",
        description: "Prefer implicit returns in closures.",
        nonTriggeringExamples: [
            "foo.map { $0 + 1 }",
            "foo.map({ $0 + 1 })",
            "foo.map { value in value + 1 }",
            "func foo() -> Int {\n  return 0\n}",
            "if foo {\n  return 0\n}",
            "var foo: Bool { return true }"
        ],
        triggeringExamples: [
            "foo.map { value in\n  ↓return value + 1\n}",
            "foo.map {\n  ↓return $0 + 1\n}"
        ],
        corrections: [
            "foo.map { value in\n  ↓return value + 1\n}": "foo.map { value in\n  value + 1\n}",
            "foo.map {\n  ↓return $0 + 1\n}": "foo.map {\n  $0 + 1\n}"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return violationRanges(in: file).flatMap {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func correct(file: File) -> [Correction] {
        let violatingRanges = file.ruleEnabled(violatingRanges: self.violationRanges(in: file), for: self)
        var correctedContents = file.contents
        var adjustedLocations = [Int]()

        for violatingRange in violatingRanges.reversed() {
            if let indexRange = correctedContents.nsrangeToIndexRange(violatingRange) {
                correctedContents = correctedContents.replacingCharacters(in: indexRange, with: "")
                adjustedLocations.insert(violatingRange.location, at: 0)
            }
        }

        file.write(correctedContents)

        return adjustedLocations.map {
            Correction(ruleDescription: type(of: self).description,
                       location: Location(file: file, characterOffset: $0))
        }
    }

    private func violationRanges(in file: File) -> [NSRange] {
        let pattern = "(?:\\bin|\\{)\\s+(return\\s+)"
        let contents = file.contents.bridge()

        return file.matchesAndSyntaxKinds(matching: pattern).flatMap { arg in
            let (result, kinds) = arg
            let range = result.range
            guard kinds == [.keyword, .keyword] || kinds == [.keyword],
                let byteRange = contents.NSRangeToByteRange(start: range.location,
                                                            length: range.length),
                let outerKind = file.structure.kinds(forByteOffset: byteRange.location).last,
                SwiftExpressionKind(rawValue: outerKind.kind) == .call else {
                    return nil
            }

            return result.rangeAt(1)
        }
    }
}
