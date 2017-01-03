//
//  NimbleOperatorRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 20/11/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import SourceKittenFramework

public struct NimbleOperatorRule: ConfigurationProviderRule, OptInRule, CorrectableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "nimble_operator",
        name: "Nimble Operator",
        description: "Prefer Nimble operator overloads over free matcher functions.",
        nonTriggeringExamples: [
            "expect(seagull.squawk) != \"Hi!\"\n",
            "expect(\"Hi!\") == \"Hi!\"\n",
            "expect(10) > 2\n",
            "expect(10) >= 10\n",
            "expect(10) < 11\n",
            "expect(10) <= 10\n",
            "expect(x) === x",
            "expect(10) == 10",
            "expect(object.asyncFunction()).toEventually(equal(1))\n",
            "expect(actual).to(haveCount(expected))\n"
        ],
        triggeringExamples: [
            "↓expect(seagull.squawk).toNot(equal(\"Hi\"))\n",
            "↓expect(12).toNot(equal(10))\n",
            "↓expect(10).to(equal(10))\n",
            "↓expect(10).to(beGreaterThan(8))\n",
            "↓expect(10).to(beGreaterThanOrEqualTo(10))\n",
            "↓expect(10).to(beLessThan(11))\n",
            "↓expect(10).to(beLessThanOrEqualTo(10))\n",
            "↓expect(x).to(beIdenticalTo(x))\n",
            "expect(10) > 2\n ↓expect(10).to(beGreaterThan(2))\n"
        ],
        corrections: [
            "↓expect(seagull.squawk).toNot(equal(\"Hi\"))\n": "expect(seagull.squawk) != \"Hi\"\n",
            "↓expect(\"Hi!\").to(equal(\"Hi!\"))\n": "expect(\"Hi!\") == \"Hi!\"\n",
            "↓expect(12).toNot(equal(10))\n": "expect(12) != 10\n",
            "↓expect(value1).to(equal(value2))\n": "expect(value1) == value2\n",
            "↓expect(value1).to(equal(10))\n": "expect(value1) == 10\n",
            "↓expect(10).to(beGreaterThan(8))\n": "expect(10) > 8\n",
            "↓expect(10).to(beGreaterThanOrEqualTo(10))\n": "expect(10) >= 10\n",
            "↓expect(10).to(beLessThan(11))\n": "expect(10) < 11\n",
            "↓expect(10).to(beLessThanOrEqualTo(10))\n": "expect(10) <= 10\n",
            "↓expect(x).to(beIdenticalTo(x))\n": "expect(x) === x\n"
        ]
    )
    public func validateFile(_ file: File) -> [StyleViolation] {
        let operators = ["equal", "beIdenticalTo", "beGreaterThan",
                         "beGreaterThanOrEqualTo", "beLessThan", "beLessThanOrEqualTo"]
        let operatorsPattern = "(" + operators.joined(separator: "|") + ")"
        let pattern = "expect\\((.(?!expect\\())+?\\)\\.to(Not)?\\(\(operatorsPattern)\\("
        let excludingKinds = SyntaxKind.commentKinds()

        let matches = file.matchPattern(pattern).filter { _, kinds in
            // excluding comment kinds and making sure first token (`expect`) is an identifier
            kinds.filter(excludingKinds.contains).isEmpty && kinds.first == .identifier
        }

        return matches.map {
            StyleViolation(ruleDescription: type(of: self).description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: $0.0.location))
        }
    }
    public func correctFile(_ file: File) -> [Correction] {
        let variable = "\\s*(.*?)\\s*"
        let patterns = [
            "expect\\(\(variable)\\)\\.to\\(equal\\(\(variable)\\)\\)": "expect($1) == $2",
            "expect\\(\(variable)\\)\\.toNot\\(equal\\(\(variable)\\)\\)": "expect($1) != $2",
            "expect\\(\(variable)\\)\\.to\\(beIdenticalTo\\(\(variable)\\)\\)": "expect($1) === $2",
            "expect\\(\(variable)\\)\\.toNot\\(beIdenticalTo\\(\(variable)\\)\\)": "expect($1) !== $2",
            "expect\\(\(variable)\\)\\.to\\(beGreaterThan\\(\(variable)\\)\\)": "expect($1) > $2",
            "expect\\(\(variable)\\)\\.to\\(beGreaterThanOrEqualTo\\(\(variable)\\)\\)": "expect($1) >= $2",
            "expect\\(\(variable)\\)\\.to\\(beLessThan\\(\(variable)\\)\\)": "expect($1) < $2",
            "expect\\(\(variable)\\)\\.to\\(beLessThanOrEqualTo\\(\(variable)\\)\\)": "expect($1) <= $2"
        ]
        return file.correctLegacyRule(self, patterns: patterns)
    }
}
