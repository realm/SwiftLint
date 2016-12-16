//
//  EmptyParametersRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/11/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct EmptyParametersRule: ConfigurationProviderRule, CorrectableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "empty_parameters",
        name: "Empty Parameters",
        description: "Prefer `() -> ` over `Void -> `.",
        nonTriggeringExamples: [
            "let abc: () -> Void = {}\n",
            "func foo(completion: () -> Void)\n",
            "func foo(completion: () thows -> Void)\n",
            "let foo: (ConfigurationTests) -> Void throws -> Void)\n",
            "let foo: (ConfigurationTests) ->   Void throws -> Void)\n",
            "let foo: (ConfigurationTests) ->Void throws -> Void)\n"
        ],
        triggeringExamples: [
            "let abc: ↓Void -> Void = {}\n",
            "func foo(completion: ↓Void -> Void)\n",
            "func foo(completion: ↓Void throws -> Void)\n",
            "let foo: ↓Void -> () throws -> Void)\n"
        ],
        corrections: [
            "let abc: Void -> Void = {}\n": "let abc: () -> Void = {}\n",
            "func foo(completion: Void -> Void)\n": "func foo(completion: () -> Void)\n",
            "func foo(completion: Void throws -> Void)\n":
                "func foo(completion: () throws -> Void)\n",
            "let foo: Void -> () throws -> Void)\n": "let foo: () -> () throws -> Void)\n"
        ]
    )

    public func validateFile(_ file: File) -> [StyleViolation] {
        return violationRanges(file: file).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    private func violationRanges(file: File) -> [NSRange] {
        let kinds = SyntaxKind.commentAndStringKinds()
        let voidPattern = "Void"
        let pattern = voidPattern + "\\s*(throws\\s+)?->"
        let excludingPattern = "->\\s*" + pattern // excludes curried functions

        return file.matchPattern(pattern,
                                 excludingSyntaxKinds: kinds,
                                 excludingPattern: excludingPattern).flatMap {
            let voidRegex = NSRegularExpression.forcePattern(voidPattern)
            return voidRegex.firstMatch(in: file.contents, options: [], range: $0)?.range
        }
    }

    public func correctFile(_ file: File) -> [Correction] {
        let violatingRanges = file.ruleEnabledViolatingRanges(violationRanges(file: file),
                                                              forRule: self)
        return writeToFile(file, violatingRanges: violatingRanges)
    }

    private func writeToFile(_ file: File, violatingRanges: [NSRange]) -> [Correction] {
        var correctedContents = file.contents
        var adjustedLocations = [Int]()

        for violatingRange in violatingRanges.reversed() {
            if let indexRange = correctedContents.nsrangeToIndexRange(violatingRange) {
                correctedContents = correctedContents
                    .replacingCharacters(in: indexRange, with: "()")
                adjustedLocations.insert(violatingRange.location, at: 0)
            }
        }

        file.write(correctedContents)

        return adjustedLocations.map {
            Correction(ruleDescription: type(of: self).description,
                       location: Location(file: file, characterOffset: $0))
        }
    }
}
