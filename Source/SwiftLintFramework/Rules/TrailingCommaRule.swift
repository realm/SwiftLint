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

    private static let triggeringExamples =  [
        "let foo = [1, 2, 3↓,]\n",
        "let foo = [1, 2, 3↓, ]\n",
        "let foo = [1, 2, 3   ↓,]\n",
        "let foo = [1: 2, 2: 3↓, ]\n",
        "struct Bar {\n let foo = [1: 2, 2: 3↓, ]\n}\n",
        "let foo = [1, 2, 3↓,] + [4, 5, 6↓,]\n",
        "let example = [ 1,\n2↓,\n // 3,\n]",
        "let foo = [\"אבג\", \"αβγ\", \"🇺🇸\"↓,]\n"
        // "foo([1: \"\\(error)\"↓,])\n"
    ]

    private static let corrections: [String: String] = {
        let fixed = triggeringExamples.map { $0.replacingOccurrences(of: "↓,", with: "") }
        var result: [String: String] = [:]
        for (triggering, correction) in zip(triggeringExamples, fixed) {
            result[triggering] = correction
        }
        return result
    }()

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
        triggeringExamples: TrailingCommaRule.triggeringExamples,
        corrections: TrailingCommaRule.corrections
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
        let nsstring = contents.bridge()
        let range = NSRange(location: 0, length: nsstring.length)
        let ranges = TrailingCommaRule.commaRegex.matches(in: contents, options: [], range: range).map { $0.range }

        // skip commas in comments
        return ranges.filter {
            let range = NSRange(location: $0.location + offset, length: $0.length)
            let kinds = file.syntaxMap.kinds(inByteRange: range)
            return !kinds.contains(where: SyntaxKind.commentKinds().contains)
        }.last.flatMap {
            nsstring.NSRangeToByteRange(start: $0.location, length: $0.length)
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
        let correctedViolations = violations.map {
            file.contents.bridge().byteRangeToNSRange(start: $0.location, length: $0.length)!
        }

        let matches = file.ruleEnabled(violatingRanges: correctedViolations, for: self)

        if matches.isEmpty { return [] }

        let correctedContents = NSMutableString(string: file.contents)

        matches.reversed().forEach { range in
            if configuration.mandatoryComma {
                correctedContents.insert(",", at: range.location)
            } else {
                correctedContents.deleteCharacters(in: range)
            }
        }

        let description = type(of: self).description
        let corrections = matches.map { range -> Correction in
            let location = Location(file: file, characterOffset: range.location)
            return Correction(ruleDescription: description, location: location)
        }

        file.write(correctedContents.bridge())

        return corrections
    }
}
