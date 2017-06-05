//
//  VoidReturnRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/12/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct VoidReturnRule: ConfigurationProviderRule, CorrectableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "void_return",
        name: "Void Return",
        description: "Prefer `-> Void` over `-> ()`.",
        nonTriggeringExamples: [
            "let abc: () -> Void = {}\n",
            "let abc: () -> (VoidVoid) = {}\n",
            "func foo(completion: () -> Void)\n",
            "let foo: (ConfigurationTests) -> () throws -> Void)\n",
            "let foo: (ConfigurationTests) ->   () throws -> Void)\n",
            "let foo: (ConfigurationTests) ->() throws -> Void)\n",
            "let foo: (ConfigurationTests) -> () -> Void)\n"
        ],
        triggeringExamples: [
            "let abc: () -> ↓() = {}\n",
            "let abc: () -> ↓(Void) = {}\n",
            "let abc: () -> ↓(   Void ) = {}\n",
            "func foo(completion: () -> ↓())\n",
            "func foo(completion: () -> ↓(   ))\n",
            "func foo(completion: () -> ↓(Void))\n",
            "let foo: (ConfigurationTests) -> () throws -> ↓())\n"
        ],
        corrections: [
            "let abc: () -> ↓() = {}\n": "let abc: () -> Void = {}\n",
            "let abc: () -> ↓(Void) = {}\n": "let abc: () -> Void = {}\n",
            "let abc: () -> ↓(   Void ) = {}\n": "let abc: () -> Void = {}\n",
            "func foo(completion: () -> ↓())\n": "func foo(completion: () -> Void)\n",
            "func foo(completion: () -> ↓(   ))\n": "func foo(completion: () -> Void)\n",
            "func foo(completion: () -> ↓(Void))\n": "func foo(completion: () -> Void)\n",
            "let foo: (ConfigurationTests) -> () throws -> ↓())\n":
                "let foo: (ConfigurationTests) -> () throws -> Void)\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return violationRanges(file: file).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    private func violationRanges(file: File) -> [NSRange] {
        let kinds = SyntaxKind.commentAndStringKinds()
        let parensPattern = "\\(\\s*(?:Void)?\\s*\\)"
        let pattern = "->\\s*\(parensPattern)\\s*(?!->)"
        let excludingPattern = "(\(pattern))\\s*(throws\\s+)?->"

        return file.match(pattern: pattern, excludingSyntaxKinds: kinds, excludingPattern: excludingPattern,
                          exclusionMapping: { $0.rangeAt(1) }).flatMap {
            let parensRegex = regex(parensPattern)
            return parensRegex.firstMatch(in: file.contents, options: [], range: $0)?.range
        }
    }

    public func correct(file: File) -> [Correction] {
        let violatingRanges = file.ruleEnabled(violatingRanges: violationRanges(file: file), for: self)
        var correctedContents = file.contents
        var adjustedLocations = [Int]()

        for violatingRange in violatingRanges.reversed() {
            if let indexRange = correctedContents.nsrangeToIndexRange(violatingRange) {
                correctedContents = correctedContents
                    .replacingCharacters(in: indexRange, with: "Void")
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
