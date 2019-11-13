import Foundation
import SourceKittenFramework

public struct NimbleOperatorRule: ConfigurationProviderRule, OptInRule, CorrectableRule, AutomaticTestableRule {
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
            "expect(success) == true",
            "expect(object.asyncFunction()).toEventually(equal(1))\n",
            "expect(actual).to(haveCount(expected))\n",
            """
            foo.method {
                expect(value).to(equal(expectedValue), description: "Failed")
                return Bar(value: ())
            }
            """
        ],
        triggeringExamples: [
            "↓expect(seagull.squawk).toNot(equal(\"Hi\"))\n",
            "↓expect(12).toNot(equal(10))\n",
            "↓expect(10).to(equal(10))\n",
            "↓expect(10, line: 1).to(equal(10))\n",
            "↓expect(10).to(beGreaterThan(8))\n",
            "↓expect(10).to(beGreaterThanOrEqualTo(10))\n",
            "↓expect(10).to(beLessThan(11))\n",
            "↓expect(10).to(beLessThanOrEqualTo(10))\n",
            "↓expect(x).to(beIdenticalTo(x))\n",
            "↓expect(success).to(beTrue())\n",
            "↓expect(success).to(beFalse())\n",
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
            "↓expect(success).to(beTrue())\n": "expect(success) == true\n",
            "↓expect(success).to(beFalse())\n": "expect(success) == false\n",
            "↓expect(success).toNot(beFalse())\n": "expect(success) != false\n",
            "↓expect(success).toNot(beTrue())\n": "expect(success) != true\n",
            "expect(10) > 2\n ↓expect(10).to(beGreaterThan(2))\n": "expect(10) > 2\n expect(10) > 2\n"
        ]
    )

    fileprivate typealias MatcherFunction = String

    fileprivate enum Arity {
        case nullary(analogueValue: String)
        case withArguments

        var hasArguments: Bool {
            guard case .withArguments = self else {
                return false
            }
            return true
        }
    }

    fileprivate typealias PredicateDescription = (to: String?, toNot: String?, arity: Arity)

    private let predicatesMapping: [MatcherFunction: PredicateDescription] = [
        "equal": (to: "==", toNot: "!=", .withArguments),
        "beIdenticalTo": (to: "===", toNot: "!==", .withArguments),
        "beGreaterThan": (to: ">", toNot: nil, .withArguments),
        "beGreaterThanOrEqualTo": (to: ">=", toNot: nil, .withArguments),
        "beLessThan": (to: "<", toNot: nil, .withArguments),
        "beLessThanOrEqualTo": (to: "<=", toNot: nil, .withArguments),
        "beTrue": (to: "==", toNot: "!=", .nullary(analogueValue: "true")),
        "beFalse": (to: "==", toNot: "!=", .nullary(analogueValue: "false"))
    ]

    public func validate(file: SwiftLintFile) -> [StyleViolation] {
        let matches = violationMatchesRanges(in: file)
        return matches.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    private func violationMatchesRanges(in file: SwiftLintFile) -> [NSRange] {
        let operandPattern = "(.(?!expect\\())+?"

        let operatorsPattern = "(" + predicatesMapping.map { name, predicateDescription in
            let argumentsPattern = predicateDescription.arity.hasArguments
                ? operandPattern
                : ""

            return "\(name)\\(\(argumentsPattern)\\)"
        }.joined(separator: "|") + ")"

        let pattern = "expect\\(\(operandPattern)\\)\\.to(Not)?\\(\(operatorsPattern)\\)"

        let excludingKinds = SyntaxKind.commentKinds

        return file.match(pattern: pattern)
            .filter { _, kinds in
                excludingKinds.isDisjoint(with: kinds) && kinds.first == .identifier
            }.map { $0.0 }
            .filter { range in
                let contents = file.linesContainer
                guard let byteRange = contents.NSRangeToByteRange(start: range.location, length: range.length) else {
                    return false
                }

                let containsCall = file.structureDictionary.structures(forByteOffset: byteRange.upperBound - 1)
                    .contains(where: { dict -> Bool in
                        return dict.expressionKind == .call && (dict.name ?? "").starts(with: "expect")
                    })

                return containsCall
            }
    }

    public func correct(file: SwiftLintFile) -> [Correction] {
        let matches = violationMatchesRanges(in: file)
            .filter { !file.ruleEnabled(violatingRanges: [$0], for: self).isEmpty }
        guard !matches.isEmpty else { return [] }

        let description = type(of: self).description
        var corrections: [Correction] = []
        var contents = file.contents

        for range in matches.sorted(by: { $0.location > $1.location }) {
            for (functionName, operatorCorrections) in predicatesMapping {
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
                 with predicateDescription: NimbleOperatorRule.PredicateDescription,
                 in range: NSRange) -> String? {
        let anything = "\\s*(.*?)\\s*"

        let toPattern = ("expect\\(\(anything)\\)\\.to\\(\(name)\\(\(anything)\\)\\)", predicateDescription.to)
        let toNotPattern = ("expect\\(\(anything)\\)\\.toNot\\(\(name)\\(\(anything)\\)\\)", predicateDescription.toNot)

        for case let (pattern, operatorString?) in [toPattern, toNotPattern] {
            let expression = regex(pattern)
            guard !expression.matches(in: self, options: [], range: range).isEmpty else {
                continue
            }

            let valueReplacementPattern: String
            switch predicateDescription.arity {
            case .nullary(let analogueValue):
                valueReplacementPattern = analogueValue
            case .withArguments:
                valueReplacementPattern = "$2"
            }

            let replacementPattern = "expect($1) \(operatorString) \(valueReplacementPattern)"

            return expression.stringByReplacingMatches(in: self,
                                                       options: [],
                                                       range: range,
                                                       withTemplate: replacementPattern)
        }

        return nil
    }
}
