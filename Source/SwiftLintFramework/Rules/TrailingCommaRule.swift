//
//  TrailingCommaRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 21/11/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private enum TrailingCommaReason: String {
    case missingTrailingCommaReason = "Multi-line collection literals should have trailing commas."
    case extraTrailingCommaReason = "Collection literals should not have trailing commas."
}

private typealias CommaRuleViolation = (index: Int, reason: TrailingCommaReason)

public struct TrailingCommaRule: ASTRule, CorrectableRule, ConfigurationProviderRule {
    public var configuration = TrailingCommaConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "trailing_comma",
        name: "Trailing Comma",
        description: "Trailing commas in arrays and dictionaries should be avoided/enforced.",
        nonTriggeringExamples: [
            "let foo = [1, 2, 3]\n",
            "let foo = []\n",
            "let foo = [:]\n",
            "let foo = [1: 2, 2: 3]\n",
            "let foo = [Void]()\n",
            "let example = [ 1,\n 2\n // 3,\n]",
            "foo([1: \"\\(error)\"])\n"
        ],
        triggeringExamples: [
            "let foo = [1, 2, 3↓,]\n",
            "let foo = [1, 2, 3↓, ]\n",
            "let foo = [1, 2, 3   ↓,]\n",
            "let foo = [1: 2, 2: 3↓, ]\n",
            "struct Bar {\n let foo = [1: 2, 2: 3↓, ]\n}\n",
            "let foo = [1, 2, 3↓,] + [4, 5, 6↓,]\n",
            "let example = [ 1,\n2↓,\n // 3,\n]"
            // "foo([1: \"\\(error)\"↓,])\n"
        ]
    )

    private static let commaRegex = regex(",", options: [.ignoreMetacharacters])

    public func validate(file: File, kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        if let (index, reason) = violationIndexAndReason(in: file, kind: kind, dictionary: dictionary) {
            return violations(file: file, byteOffset: index, reason: reason.rawValue)
        } else {
            return []
        }
    }

    private func violationIndexAndReason(in file: File, kind: SwiftExpressionKind,
                                         dictionary: [String: SourceKitRepresentable]) -> CommaRuleViolation? {
        let allowedKinds: [SwiftExpressionKind] = [.array, .dictionary]

        guard let bodyOffset = dictionary.bodyOffset,
            let bodyLength = dictionary.bodyLength,
            allowedKinds.contains(kind) else {
                return nil
        }

        let endPositions = dictionary.elements.flatMap { dictionary -> Int? in
            guard let offset = dictionary.offset,
                let length = dictionary.length else {
                    return nil
            }

            return offset + length
        }

        guard let lastPosition = endPositions.max(), bodyLength + bodyOffset >= lastPosition else {
            return nil
        }

        let contents = file.contents.bridge()
        if let (startLine, _) = contents.lineAndCharacter(forByteOffset: bodyOffset),
            let (endLine, _) = contents.lineAndCharacter(forByteOffset: lastPosition),
            configuration.mandatoryComma && startLine == endLine {
            // shouldn't trigger if mandatory comma style and is a single-line declaration
            return nil
        }

        let length = bodyLength + bodyOffset - lastPosition
        let contentsAfterLastElement = contents.substringWithByteRange(start: lastPosition, length: length) ?? ""

        // if a trailing comma is not present
        guard let commaIndex = trailingCommaIndex(contents: contentsAfterLastElement, file: file,
                                                  offset: lastPosition) else {
            guard configuration.mandatoryComma else {
                return nil
            }

            return (lastPosition, .missingTrailingCommaReason)
        }

        // trailing comma is present, which is a violation if mandatoryComma is false
        guard !configuration.mandatoryComma else {
            return nil
        }

        let violationOffset = lastPosition + commaIndex
        return (violationOffset, .extraTrailingCommaReason)
    }

    private func violations(file: File, byteOffset: Int, reason: String) -> [StyleViolation] {
        return [
            StyleViolation(ruleDescription: type(of: self).description,
                severity: configuration.severityConfiguration.severity,
                location: Location(file: file, byteOffset: byteOffset),
                reason: reason
            )
        ]
    }

    private func trailingCommaIndex(contents: String, file: File, offset: Int) -> Int? {
        let range = NSRange(location: 0, length: contents.bridge().length)
        let ranges = TrailingCommaRule.commaRegex.matches(in: contents, options: [], range: range).map { $0.range }

        // skip commas in comments
        return ranges.filter {
            let range = NSRange(location: $0.location + offset, length: $0.length)
            let kinds = file.syntaxMap.tokens(inByteRange: range).flatMap { SyntaxKind(rawValue: $0.type) }
            return kinds.filter(SyntaxKind.commentKinds().contains).isEmpty
        }.last.flatMap {
            contents.bridge().NSRangeToByteRange(start: $0.location, length: $0.length)
        }?.location
    }

    public func correct(file: File) -> [Correction] {
        let violatingIndexes = file.structure.dictionary.substructure.flatMap { sub -> CommaRuleViolation? in
            guard let kind = SwiftExpressionKind(rawValue: sub.kind ?? "") else { return nil }
            return violationIndexAndReason(in: file, kind: kind, dictionary: sub)
        }

        let adjustedIndexes = violatingIndexes.reduce([CommaRuleViolation]()) { adjustedIndexes, element in
            let correction: Int
            switch element.reason {
            case .missingTrailingCommaReason:
                correction = adjustedIndexes.count
            case .extraTrailingCommaReason:
                correction = -adjustedIndexes.count
            }

            return adjustedIndexes + [(element.index + correction, element.reason)]
        }

        var correctedContents = file.contents

        adjustedIndexes.forEach {
            let stringIndex = correctedContents.index(correctedContents.startIndex, offsetBy: $0.index)
            switch $0.reason {
            case .missingTrailingCommaReason:
                correctedContents.insert(",", at: stringIndex)
            case .extraTrailingCommaReason:
                correctedContents.remove(at: stringIndex)
            }
        }

        file.write(correctedContents)

        return adjustedIndexes.map {
            Correction(ruleDescription: type(of: self).description,
                       location: Location(file: file, characterOffset: $0.index))
        }
    }
}
