//
//  EmptyParenthesesWithTrailingClosureRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/11/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct EmptyParenthesesWithTrailingClosureRule: ASTRule, CorrectableRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "empty_parentheses_with_trailing_closure",
        name: "Empty Parentheses with Trailing Closure",
        description: "When using trailing closures, empty parentheses should be avoided " +
                     "after the method call.",
        nonTriggeringExamples: [
            "[1, 2].map { $0 + 1 }\n",
            "[1, 2].map({ $0 + 1 })\n",
            "[1, 2].reduce(0) { $0 + $1 }",
            "[1, 2].map { number in\n number + 1 \n}\n",
            "let isEmpty = [1, 2].isEmpty()\n",
            "UIView.animateWithDuration(0.3, animations: {\n" +
            "   self.disableInteractionRightView.alpha = 0\n" +
            "}, completion: { _ in\n" +
            "   ()\n" +
            "})"
        ],
        triggeringExamples: [
            "[1, 2].map↓() { $0 + 1 }\n",
            "[1, 2].map↓( ) { $0 + 1 }\n",
            "[1, 2].map↓() { number in\n number + 1 \n}\n",
            "[1, 2].map↓(  ) { number in\n number + 1 \n}\n"
        ],
        corrections: [
            "[1, 2].map↓() { $0 + 1 }\n": "[1, 2].map { $0 + 1 }\n",
            "[1, 2].map↓( ) { $0 + 1 }\n": "[1, 2].map { $0 + 1 }\n",
            "[1, 2].map↓() { number in\n number + 1 \n}\n": "[1, 2].map { number in\n number + 1 \n}\n",
            "[1, 2].map↓(  ) { number in\n number + 1 \n}\n": "[1, 2].map { number in\n number + 1 \n}\n"
        ]
    )

    private static let emptyParenthesesRegex = regex("^\\s*\\(\\s*\\)")

    public func validate(file: File, kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        return violationRanges(in: file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    private func violationRanges(in file: File, kind: SwiftExpressionKind,
                                 dictionary: [String: SourceKitRepresentable]) -> [NSRange] {
        guard kind == .call else {
            return []
        }

        guard let offset = dictionary.offset,
            let length = dictionary.length,
            let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            let bodyLength = dictionary.bodyLength,
            bodyLength > 0 else {
                return []
        }

        let rangeStart = nameOffset + nameLength
        let rangeLength = (offset + length) - (nameOffset + nameLength)
        let regex = EmptyParenthesesWithTrailingClosureRule.emptyParenthesesRegex

        guard let range = file.contents.bridge().byteRangeToNSRange(start: rangeStart, length: rangeLength),
            let match = regex.firstMatch(in: file.contents, options: [], range: range)?.range,
            match.location == range.location else {
                return []
        }

        return [match]
    }

    private func violationRanges(in file: File, dictionary: [String: SourceKitRepresentable]) -> [NSRange] {
        return dictionary.substructure.flatMap { subDict -> [NSRange] in
            guard let kindString = subDict.kind,
                let kind = SwiftExpressionKind(rawValue: kindString) else {
                    return []
            }
            return violationRanges(in: file, dictionary: subDict) +
                violationRanges(in: file, kind: kind, dictionary: subDict)
        }
    }

    private func violationRanges(in file: File) -> [NSRange] {
        return violationRanges(in: file, dictionary: file.structure.dictionary).sorted { lhs, rhs in
            lhs.location < rhs.location
        }
    }

    public func correct(file: File) -> [Correction] {
        let violatingRanges = file.ruleEnabled(violatingRanges: violationRanges(in: file), for: self)
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
}
