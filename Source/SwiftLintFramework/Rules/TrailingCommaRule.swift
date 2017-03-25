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
        ],
        corrections: [
            "let foo = [1, 2, 3↓,]\n": "let foo = [1, 2, 3]\n",
            "let foo = [1, 2, 3↓, ]\n": "let foo = [1, 2, 3 ]\n",
            "let foo = [1, 2, 3   ↓,]\n": "let foo = [1, 2, 3   ]\n",
            "let foo = [1: 2, 2: 3↓, ]\n": "let foo = [1: 2, 2: 3 ]\n",
            "struct Bar {\n let foo = [1: 2, 2: 3↓, ]\n}\n": "struct Bar {\n let foo = [1: 2, 2: 3 ]\n}\n",
            "let foo = [1, 2, 3↓,] + [4, 5, 6↓,]\n": "let foo = [1, 2, 3] + [4, 5, 6]\n",
            "let foo = [\"אבג\", \"αβγ\", \"🇺🇸\"↓,]\n": "let foo = [\"אבג\", \"αβγ\", \"🇺🇸\"]\n"
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

    private func violationRanges(in file: File,
                                 dictionary: [String: SourceKitRepresentable]) -> [NSRange] {
        return dictionary.substructure.flatMap { subDict -> [NSRange] in
            var violations = violationRanges(in: file, dictionary: subDict)

            if let kindString = subDict.kind,
                let kind = KindType(rawValue: kindString),
                let index = violationIndexAndReason(in: file, kind: kind, dictionary: subDict)?.index {
                violations += [NSRange(location: index, length: 1)]
            }

            return violations
        }
    }

    public func correct(file: File) -> [Correction] {
        let violations = violationRanges(in: file, dictionary: file.structure.dictionary)
        let correctedViolations = violations.map { range -> NSRange in
            let index = file.contents.utf8.index(file.contents.utf8.startIndex,
                                                 offsetBy: range.location)
            let index16 = index.samePosition(in: file.contents.utf16)!
            let correctedCharacterOffset = file.contents.utf16.distance(from: file.contents.utf16.startIndex,
                                                                        to: index16)
            return NSRange(location: correctedCharacterOffset, length: range.length)
        }

        let matches = file.ruleEnabled(violatingRanges: correctedViolations, for: self).map { $0.location }

        if matches.isEmpty { return [] }

        var correctedContents = file.contents

        matches.reversed().forEach { offset in
            let index = correctedContents.utf16.index(correctedContents.utf16.startIndex, offsetBy: offset)
            let correctedIndex = index.samePosition(in: correctedContents)!
            if configuration.mandatoryComma {
                correctedContents.characters.insert(",", at: correctedIndex)
            } else {
                correctedContents.characters.remove(at: correctedIndex)
            }
        }

        let description = type(of: self).description
        let corrections = matches.map { offset -> Correction in
            let location = Location(file: file, characterOffset: offset)
            return Correction(ruleDescription: description, location: location)
        }

        file.write(correctedContents)

        return corrections
    }
}
