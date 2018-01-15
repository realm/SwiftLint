//
//  DiscouragedOptinalCollection.swift
//  SwiftLint
//
//  Created by Ornithologist Coder on 1/10/18.
//  Copyright © 2018 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct DiscouragedOptionalCollectionRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "discouraged_optional_collection",
        name: "Discouraged Optional Collection",
        description: "Prefer empty collection over optional collection.",
        kind: .idiomatic,
        nonTriggeringExamples: DiscouragedOptionalCollectionExamples.nonTriggeringExamples,
        triggeringExamples: DiscouragedOptionalCollectionExamples.triggeringExamples
    )

    public func validate(file: File,
                         kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        var offsets: [Int] = []

        if SwiftDeclarationKind.variableKinds.contains(kind) {
            offsets.append(contentsOf: variableViolations(file: file, dictionary: dictionary))
        }

        if SwiftDeclarationKind.functionKinds.contains(kind) {
            offsets.append(contentsOf: functionViolations(file: file, dictionary: dictionary))
        }

        return offsets.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: $0))
        }
    }

    // MARK: - Private

    private func variableViolations(file: File, dictionary: [String: SourceKitRepresentable]) -> [Int] {
        guard
            let offset = dictionary.offset,
            let typeName = dictionary.typeName else { return [] }

        return typeName.optionalCollectionRanges().map { _ in offset }
    }

    private func functionViolations(file: File, dictionary: [String: SourceKitRepresentable]) -> [Int] {
        guard
            let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            let length = dictionary.length,
            let offset = dictionary.offset,
            case let start = nameOffset + nameLength,
            case let end = dictionary.bodyOffset ?? offset + length,
            case let contents = file.contents.bridge(),
            let range = contents.byteRangeToNSRange(start: start, length: end - start),
            let match = file.match(pattern: "->\\s*(.*?)\\{", excludingSyntaxKinds: excludingKinds, range: range).first
            else { return [] }

        return contents.substring(with: match).optionalCollectionRanges().map { _ in nameOffset }
    }

    private let excludingKinds = SyntaxKind.allKinds.subtracting([.typeidentifier])
}

private extension String {
    /// Ranges of optional collections within the bounds of the string.
    ///
    /// - Returns: An array of ranges.
    func optionalCollectionRanges() -> [Range<String.Index>] {
        let squareBrackets = balancedRanges(between: "[", and: "]").flatMap { range -> Range<String.Index>? in
            guard
                range.upperBound < endIndex,
                let nextIndex = index(range.upperBound, offsetBy: 1, limitedBy: endIndex)
                else { return nil }

            let isOptional = self[range.upperBound] == "?"

            return isOptional ? Range(range.lowerBound..<nextIndex) : nil
        }

        let angleBrackets = balancedRanges(between: "<", and: ">").flatMap { range -> Range<String.Index>? in
            guard
                range.upperBound < endIndex,
                let initialIndex = index(range.lowerBound, offsetBy: -3, limitedBy: startIndex),
                let nextIndex = index(range.upperBound, offsetBy: 1, limitedBy: endIndex)
                else { return nil }

            let isSet = self[initialIndex..<range.lowerBound] == "Set"
            let isOptional = self[range.upperBound] == "?"

            return isSet && isOptional ? Range(initialIndex..<nextIndex) : nil
        }

        return squareBrackets + angleBrackets
    }

    /// Indices of character within the bounds of the string.
    ///
    /// - Parameter character: The character to look for.
    /// - Returns: Array of indices.
    private func indices(of character: Character) -> [String.Index] {
        return indices.flatMap { self[$0] == character ? $0 : nil }
    }

    /// Ranges of balanced substrings.
    ///
    /// - Parameters:
    ///   - prefix: The prefix to look for.
    ///   - suffix: The suffix to look for.
    /// - Returns: Array of ranges of balanced substrings
    private func balancedRanges(between prefix: Character, and suffix: Character) -> [Range<String.Index>] {
        return indices(of: prefix).flatMap { prefixIndex in
            var pairCount = 0
            var currentIndex = prefixIndex
            var foundCharacter = false

            while currentIndex < endIndex {
                let character = self[currentIndex]
                currentIndex = index(after: currentIndex)

                if character == prefix { pairCount += 1 }
                if character == suffix { pairCount -= 1 }
                if pairCount != 0 { foundCharacter = true }
                if pairCount == 0 && foundCharacter { break }
            }

            return pairCount == 0 && foundCharacter ? Range(prefixIndex..<currentIndex) : nil
        }
    }
}
