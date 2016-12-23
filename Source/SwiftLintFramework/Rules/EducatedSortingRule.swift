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
        guard let originalArray = self as? [String] else {
            return 0.0
        }

        let array = originalArray.map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
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
            "let foo = [\"Alpha\", \"Bravo\", \"Charlie\", \"Delta\"]\n",
            "let foo = [\"Alpha\"]\n",
            "let foo = [\"Bravo\", \"Alpha\"]\n",
            "let foo = [\"Charlie\", \"Bravo\", \"Alpha\"]\n",
            "let foo = []\n"
        ],
        triggeringExamples: [
            "let foo = [\"Charlie\", \"Alpha\", \"Bravo\"]\n",
            "let foo = [\"Bravo\", \"Charlie\", \"Alpha\", \"Delta\"]\n",
            "let foo = [\"Alpha\", \"Bravo\", \"Charlie\", \"Delta\", \"Foxtrot\", \"Echo\"]\n"
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

        guard let contents = file.contents.substringWithByteRange(start: bodyOffset, length: bodyLength) else {
            return []
        }

        let items = contents.components(separatedBy: ",")

        guard items.count >= configuration.minimumItems else {
            return []
        }

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
                    reason: arrayEducatedSortingReason + String(format: " (%.1f%% sorted)", sortedness * 100.0)
                )
            ]
        } else {
            return []
        }
    }
}
