//
//  InferredSortingRule.swift
//  SwiftLint
//
//  Created by Jamie Edge on 23/12/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private let arrayInferredSortingReason = "Array elements should be sorted."

extension Sequence where Iterator.Element == String {
    /// Determines how sorted the sequence is on a scale from 0.0 to 1.0.
    fileprivate func sortedness(caseSensitive: Bool) -> Float {
        guard let array = self as? [String] else {
            return 0.0
        }

        let sortedArray = caseSensitive ? array.sorted() : array.sorted(by:) { $0.lowercased() < $1.lowercased() }
        let startIndex = array.startIndex
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
            if index == startIndex && index == sortedIndex {
                score += 1
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

public struct InferredSortingRule: ASTRule, ConfigurationProviderRule, OptInRule {
    public var configuration = InferredSortingConfiguration()

    public init() { }

    public static let description = RuleDescription(
        identifier: "inferred_sorting",
        name: "Inferred Sorting",
        description: "Elements should be sorted in alphabetical and numerical order.",
        nonTriggeringExamples: [
            "let foo = [\"Alpha\"]\n",
            "let foo = [\"Alpha\", \"Bravo\", \"Charlie\", \"Delta\"]\n",
            "let foo = [\"Alpha\", \"Bravo\", \"Charlie\", \"Delta\", \"Echo\", \"Foxtrot\", \"Golf\", \"Hotel\"]\n",
            "let foo = [\"Hotel\", \"Bravo\", \"Charlie\", \"Delta\", \"Echo\", \"Foxtrot\", \"Golf\", \"Alpha\"]\n",
            "let foo = [\"Bravo\", \"Alpha\"]\n",
            "let foo = [\"Charlie\", \"Alpha\", \"Bravo\"]\n",
            "let foo = [\"Charlie\", \"Bravo\", \"Alpha\"]\n",
            "let foo = []\n"
        ],
        triggeringExamples: [
            "let foo = [\"Alpha\", \"Bravo\", \"Charlie\", \"Delta\", \"Echo\", \"Foxtrot\", \"Golf\", \"Hotel\"," +
                        "\"Juliet\", \"India\"]\n",
            "let foo = [\"November\" \"Alpha\", \"Bravo\", \"Charlie\", \"Delta\", \"Echo\", \"Foxtrot\", \"Golf\"," +
                        "\"Hotel\", \"India\", \"Juliet\", \"Kilo\", \"Lima\", \"Mike\"]\n"
        ]
    )

    private static let allowedKinds: [SwiftExpressionKind] = [.array]
    private static let expectedElementKind = "source.lang.swift.structure.elem.expr"

    public func validateFile(_ file: File,
                             kind: SwiftExpressionKind,
                             dictionary: [String : SourceKitRepresentable]) -> [StyleViolation] {
        guard let bodyOffset = (dictionary["key.bodyoffset"] as? Int64).flatMap({ Int($0) }),
            let elements = dictionary["key.elements"] as? [SourceKitRepresentable],
            type(of: self).allowedKinds.contains(kind) else {
                return []
        }

        let contents = file.contents.bridge()

        let items = elements.flatMap { element -> String? in
            guard let dictionary = element as? [String: SourceKitRepresentable],
                let elementOffset = (dictionary["key.offset"] as? Int64).flatMap({ Int($0) }),
                let elementLength = (dictionary["key.length"] as? Int64).flatMap({ Int($0) }),
                (dictionary["key.kind"] as? String) == type(of: self).expectedElementKind else {
                    return nil
            }

            return contents.substringWithByteRange(start: elementOffset, length: elementLength)
        }

        guard items.count >= configuration.minimumItems else {
            return []
        }

        return violations(items: items, file: file, offset: bodyOffset)
    }

    private func violations(items: [String], file: File, offset: Int) -> [StyleViolation] {
        let sortedness = items.sortedness(caseSensitive: configuration.caseSensitive)

        if sortedness < 1.0 && sortedness >= configuration.threshold {
            return [
                StyleViolation(
                    ruleDescription: type(of: self).description,
                    severity: configuration.severityConfiguration.severity,
                    location: Location(file: file, byteOffset: offset),
                    reason: arrayInferredSortingReason + String(format: " (%.1f%% sorted)", sortedness * 100.0)
                )
            ]
        } else {
            return []
        }
    }
}
