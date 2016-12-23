//
//  EducatedSortingRule.swift
//  SwiftLint
//
//  Created by Jamie Edge on 23/12/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private let arrayEducatedSortingReason = "Array elements should be sorted."

extension Sequence where Iterator.Element == String {
    /// Determines how sorted the sequence is on a scale from 0.0 to 1.0.
    fileprivate var sortedness: Float {
        guard let array = self as? [String] else {
            return 0.0
        }

        let sortedArray = array.sorted()
        let maxIndex = array.endIndex - 1
        var score = 0

        // Test order by scoring if each element has the next correct element.
        for (index, element) in array.enumerated() {
            // Skip the last element - there is no next element to test.
            guard index < maxIndex else {
                continue
            }

            // Should never fail, but requires that all elements of the
            // unsorted array are in the sorted one.
            guard let sortedIndex = sortedArray.index(of: element) else {
                continue
            }

            // Check the first element using direct comparison.
            if index == array.startIndex {
                if index == sortedIndex {
                    score += 1
                }
            }

            // Require an element after the current sorted one.
            guard sortedIndex < maxIndex else {
                continue
            }

            let nextElement = array[index + 1]
            let nextSortedElement = sortedArray[sortedIndex + 1]

            if nextElement == nextSortedElement {
                score += 1
            }
        }

        return Float(score) / Float(array.count)
    }
}

public struct EducatedSortingRule: ASTRule, ConfigurationProviderRule {
    public var configuration = EducatedSortingConfiguration()

    public init() { }

    public static let description = RuleDescription(
        identifier: "educated_sorting",
        name: "Educated Sorting",
        description: "Elements should be sorted in alphabetical and numerical order.",
        nonTriggeringExamples: [
            "let foo = [\"Alpha\", \"Bravo\", \"Charlie\"]\n",
            "let foo = [\"Alpha\"]\n",
            "let foo = []\n"
        ],
        triggeringExamples: [
            "let foo = [\"Bravo\", \"Alpha\"]\n",
            "let foo = [\"Bravo\", \"Charlie\", \"Alpha\"]\n"
        ],
        corrections: [
            "let foo = [\"Bravo\", \"Alpha\"]\n": "let foo = [\"Alpha\", \"Bravo\"]\n",
            "let foo = [\"Bravo\", \"Charlie\", \"Alpha\"]\n": "let foo = [\"Alpha\", \"Bravo\", \"Charlie\"]\n"
        ]
    )

    private static let allowedKinds: [SwiftExpressionKind] = [.array]

    public func validateFile(_ file: File,
                             kind: SwiftExpressionKind,
                             dictionary: [String : SourceKitRepresentable]) -> [StyleViolation] {
        guard let bodyOffset = (dictionary["key.bodyoffset"] as? Int64).flatMap({ Int($0) }),
            let bodyLength = (dictionary["key.bodylength"] as? Int64).flatMap({ Int($0) }),
            type(of: self).allowedKinds.contains(kind) else {
                return []
        }

        let contents = file.contents.bridge().substring(with: NSRange(location: bodyOffset,
                                                                      length: bodyLength)) as String

        let items = contents.components(separatedBy: .whitespacesAndNewlines).joined().components(separatedBy: ",")

        return violations(items: items, file: file, offset: bodyOffset)
    }

    private func violations(items: [String], file: File, offset: Int) -> [StyleViolation] {
        let sortedness = items.sortedness

        if sortedness < 1.0 && sortedness >= configuration.threshold {
            return [
                StyleViolation(
                    ruleDescription: type(of: self).description,
                    severity: configuration.severityConfiguration.severity,
                    location: Location(file: file, byteOffset: offset),
                    reason: arrayEducatedSortingReason
                )
            ]
        } else {
            return []
        }
    }
}
