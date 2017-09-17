//
//  NimbleOperatorRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 20/11/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct NimbleOperatorRule: ConfigurationProviderRule, OptInRule, CorrectableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "nimble_operator",
        name: "Nimble Operator",
        description: "Prefer Nimble operator overloads over free matcher functions.",
        kind: .idiomatic,
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
            "↓expect(   value1  ).to(equal(  value2.foo))\n": "expect(value1) == value2.foo\n",
            "↓expect(value1).to(equal(10))\n": "expect(value1) == 10\n",
            "↓expect(10).to(beGreaterThan(8))\n": "expect(10) > 8\n",
            "↓expect(10).to(beGreaterThanOrEqualTo(10))\n": "expect(10) >= 10\n",
            "↓expect(10).to(beLessThan(11))\n": "expect(10) < 11\n",
            "↓expect(10).to(beLessThanOrEqualTo(10))\n": "expect(10) <= 10\n",
            "↓expect(x).to(beIdenticalTo(x))\n": "expect(x) === x\n",
            "expect(10) > 2\n ↓expect(10).to(beGreaterThan(2))\n": "expect(10) > 2\n expect(10) > 2\n"
        ]
    )

    fileprivate typealias Operators = (to: String?, toNot: String?)
    fileprivate typealias MatcherFunction = String

    fileprivate let operatorsMapping: [MatcherFunction: Operators] = [
        "equal": (to: "==", toNot: "!="),
        "beIdenticalTo": (to: "===", toNot: "!=="),
        "beGreaterThan": (to: ">", toNot: nil),
        "beGreaterThanOrEqualTo": (to: ">=", toNot: nil),
        "beLessThan": (to: "<", toNot: nil),
        "beLessThanOrEqualTo": (to: "<=", toNot: nil)
    ]

    public func validate(file: File) -> [StyleViolation] {
        let matches = violationMatchesRanges(in: file)
        return matches.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    private func violationMatchesRanges(in file: File) -> [NSRange] {
        let operatorNames = operatorsMapping.keys
        let operatorsPattern = "(" + operatorNames.joined(separator: "|") + ")"

        let variablePattern = "(.(?!expect\\())+?"
        let pattern = "expect\\(\(variablePattern)\\)\\.to(Not)?\\(\(operatorsPattern)\\(\(variablePattern)\\)\\)"

        let excludingKinds = SyntaxKind.commentKinds

        return file.match(pattern: pattern)
            .filter { _, kinds in
                kinds.filter(excludingKinds.contains).isEmpty && kinds.first == .identifier
            }.map { $0.0 }
    }

    public func correct(file: File) -> [Correction] {
        let matches = violationMatchesRanges(in: file)
            .filter { !file.ruleEnabled(violatingRanges: [$0], for: self).isEmpty }
        guard !matches.isEmpty else { return [] }

        let description = type(of: self).description
        var corrections: [Correction] = []
        var contents = file.contents

        for range in matches.sorted(by: { $0.location > $1.location }) {
            for (functionName, operatorCorrections) in operatorsMapping {
                guard let correctedString = contents.replace(function: functionName,
                                                             with: operatorCorrections,
                                                             in: range)
                else {
                    continue
                }

                contents = correctedString
                let correction = Correction(ruleDescription: description,
                                            location: Location(file: file, characterOffset: range.location))
                corrections.insert(correction, at: 0)
                break
            }
        }

        file.write(contents)
        return corrections
    }
}

private extension String {
    /// Returns corrected string if the correction is possible, otherwise returns nil.
    func replace(function name: NimbleOperatorRule.MatcherFunction,
                 with operators: NimbleOperatorRule.Operators,
                 in range: NSRange) -> String? {

        let anything = "\\s*(.*?)\\s*"

        let toPattern = ("expect\\(\(anything)\\)\\.to\\(\(name)\\(\(anything)\\)\\)", operators.to)
        let toNotPattern = ("expect\\(\(anything)\\)\\.toNot\\(\(name)\\(\(anything)\\)\\)", operators.toNot)

        var correctedString: String?

        for (pattern, operatorString) in [toPattern, toNotPattern] {
            guard let operatorString = operatorString else {
                continue
            }

            let expression = regex(pattern)
            if !expression.matches(in: self, options: [], range: range).isEmpty {
                correctedString = expression.stringByReplacingMatches(in: self,
                                                                      options: [],
                                                                      range: range,
                                                                      withTemplate: "expect($1) \(operatorString) $2")
                break
            }
        }

        return correctedString
    }
}
