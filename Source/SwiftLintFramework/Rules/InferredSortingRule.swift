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

private protocol InferredSortingItem: Comparable {
    static func sorted(items: [Self], caseSensitive: Bool) -> [Self]
}

extension Double: InferredSortingItem {
    static func sorted(items: [Double], caseSensitive: Bool) -> [Double] {
        return items.sorted()
    }
}

extension String: InferredSortingItem {
    static func sorted(items: [String], caseSensitive: Bool) -> [String] {
        // Due to a bug in Swift, String.sorted() is case-insensitive on Linux.
        // https://bugs.swift.org/browse/SR-530
        #if os(Linux)
            return items.sorted(by:) {
                let x = $0.bridge()
                return (caseSensitive ? x.compare($1) : x.caseInsensitiveCompare($1)) == .orderedAscending
            }
        #else
            return caseSensitive ? items.sorted() : items.sorted(by:) { $0.lowercased() < $1.lowercased() }
        #endif
    }
}

private extension Array where Element: InferredSortingItem {
    /// Determines how sorted the sequence is on a scale from 0.0 to 1.0.
    func sortedness(caseSensitive: Bool) -> Float {
        let array = self
        let sortedArray = Element.sorted(items: array, caseSensitive: caseSensitive)
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
        kind: .style,
        nonTriggeringExamples: [
            "let foo = [\"Alpha\"]\n",
            "let foo = [\"Alpha\", \"Bravo\", \"Charlie\", \"Delta\"]\n",
            "let foo = [\"Alpha\", \"Bravo\", \"Charlie\", \"Delta\", \"Echo\", \"Foxtrot\", \"Golf\", \"Hotel\"]\n",
            "let foo = [\"Hotel\", \"Bravo\", \"Charlie\", \"Delta\", \"Echo\", \"Foxtrot\", \"Golf\", \"Alpha\"]\n",
            "let foo = [\"Bravo\", \"Alpha\"]\n",
            "let foo = [\"Charlie\", \"Alpha\", \"Bravo\"]\n",
            "let foo = [\"Charlie\", \"Bravo\", \"Alpha\"]\n",
            "let foo = []\n",
            "let stats = [3_000, 4_000, 5_000, 7_000, 8_000, 13_000, 14_000, 15_000, 17_000, 18_000]\n",
            "let stats = [3_000, 4_000, 5_000, 7_000, 8_000, 13000, 14_000, 15_000, 17_000, 18_000]\n"
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

    public func validate(file: File,
                         kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard let bodyOffset = dictionary.bodyOffset,
            type(of: self).allowedKinds.contains(kind) else {
                return []
        }

        let itemsRanges = dictionary.elements.flatMap { element -> NSRange? in
            guard let elementOffset = element.offset,
                let elementLength = element.length,
                element.kind == type(of: self).expectedElementKind else {
                    return nil
            }

            return NSRange(location: elementOffset, length: elementLength)
        }

        guard itemsRanges.count >= configuration.minimumItems else {
            return []
        }

        if let items = numberElements(from: itemsRanges, file: file) {
            return violations(items: items, file: file, offset: bodyOffset)
        } else {
            let items = stringElements(from: itemsRanges, file: file)
            return violations(items: items, file: file, offset: bodyOffset)
        }
    }

    private func numberElements(from elements: [NSRange], file: File) -> [Double]? {
        let contents = file.contents.bridge()
        var result = [Double]()
        for range in elements {
            let tokens = file.syntaxMap.tokens(inByteRange: range)
            guard tokens == [numberToken(range: range)],
                let substring = contents.substringWithByteRange(start: range.location, length: range.length),
                let value = Double(substring.replacingOccurrences(of: "_", with: "")) else {
                    return nil
            }

            result.append(value)
        }

        return result
    }

    private func numberToken(range: NSRange) -> SyntaxToken {
        return SyntaxToken(type: SyntaxKind.number.rawValue, offset: range.location, length: range.length)
    }

    private func stringElements(from elements: [NSRange], file: File) -> [String] {
        let contents = file.contents.bridge()
        let elements = elements.flatMap {
            contents.substringWithByteRange(start: $0.location, length: $0.length)
        }

        return elements
    }

    private func violations<T: InferredSortingItem>(items: [T], file: File,
                                                    offset: Int) -> [StyleViolation] {
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
