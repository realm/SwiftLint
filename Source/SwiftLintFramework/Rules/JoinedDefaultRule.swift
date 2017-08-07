//
//  JoinedDefaultRule.swift
//  SwiftLint
//
//  Created by Ornithologist Coder on 8/3/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct JoinedDefaultParameterRule: ASTRule, ConfigurationProviderRule, OptInRule, CorrectableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "joined_default_parameter",
        name: "Joined Default Parameter",
        description: "Discouraged explicit usage of the default separator.",
        kind: .idiomatic,
        nonTriggeringExamples: [
            "let foo = bar.joined()",
            "let foo = bar.joined(separator: \",\")",
            "let foo = bar.joined(separator: toto)"
        ],
        triggeringExamples: [
            "let foo = bar.joined(separator: ↓\"\")",
            "let foo = bar.filter(toto)\n" +
            "             .joined(separator: ↓\"\")"
        ],
        corrections: [
            "let foo = bar.joined(↓separator: \"\")": "let foo = bar.joined()",
            "let foo = bar.filter(toto)\n.joined(↓separator: \"\")": "let foo = bar.filter(toto)\n.joined()"
        ]
    )

    // MARK: - ASTRule

    public func validate(file: File,
                         kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard
            kind == .call,
            dictionary.name?.hasSuffix(".joined") == true,
            let defaultSeparatorOffset = defaultSeparatorOffset(dictionary: dictionary, file: file)
            else { return [] }

        return [StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: defaultSeparatorOffset))]
    }

    private func defaultSeparatorOffset(dictionary: [String: SourceKitRepresentable], file: File) -> Int? {
        guard
            dictionary.enclosedArguments.count == 1,
            let argument = dictionary.enclosedArguments.first,
            let argumentBodyOffset = argument.bodyOffset,
            let argumentBodyLength = argument.bodyLength,
            argument.name == "separator"
            else { return nil }

        let body = file.contents.bridge().substringWithByteRange(start: argumentBodyOffset, length: argumentBodyLength)
        return body == "\"\"" ? argumentBodyOffset : nil
    }

    // MARK: - CorrectableRule

    public func correct(file: File) -> [Correction] {
        let violatingRanges = violationRanges(in: file, dictionary: file.structure.dictionary)
        let matches = file.ruleEnabled(violatingRanges: violatingRanges, for: self)
        var correctedContents = file.contents
        var adjustedLocations: [Int] = []

        for violatingRange in matches.reversed() {
            if let range = file.contents.nsrangeToIndexRange(violatingRange) {
                correctedContents = correctedContents.replacingCharacters(in: range, with: "")
                adjustedLocations.insert(violatingRange.location, at: 0)
            }
        }

        file.write(correctedContents)

        return adjustedLocations.map {
            Correction(ruleDescription: type(of: self).description, location: Location(file: file, characterOffset: $0))
        }
    }

    private func violationRanges(in file: File, dictionary: [String: SourceKitRepresentable]) -> [NSRange] {
        return dictionary.substructure.flatMap { subDictionary -> [NSRange] in
            let violations = violationRanges(in: file, dictionary: subDictionary)

            guard
                // is it calling a method '.joined' and passing a single argument?
                subDictionary.kind == SwiftExpressionKind.call.rawValue,
                subDictionary.name?.hasSuffix(".joined") == true,
                subDictionary.enclosedArguments.count == 1
                else { return violations }

            guard
                // is this single argument called 'separator'?
                let argument = subDictionary.enclosedArguments.first,
                let offset = argument.offset,
                let length = argument.length,
                argument.name == "separator"
                else { return violations }

            guard
                // is this single argument the default parameter?
                let bodyOffset = argument.bodyOffset,
                let bodyLength = argument.bodyLength,
                let body = file.contents.bridge().substringWithByteRange(start: bodyOffset, length: bodyLength),
                body == "\"\""
                else { return violations }

            guard
                let range = file.contents.bridge().byteRangeToNSRange(start: offset, length: length)
                else { return violations }

            return violations + [range]
        }
    }
}
