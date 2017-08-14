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
            "let foo = bar.joined(↓separator: \"\")",
            "let foo = bar.filter(toto)\n" +
            "             .joined(↓separator: \"\")"
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
        return violationRanges(in: file, kind: kind, dictionary: dictionary).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    // MARK: - CorrectableRule

    public func correct(file: File) -> [Correction] {
        let matches = file.ruleEnabled(violatingRanges: violationRanges(in: file), for: self)
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

    // MARK: - Private

    private func violationRanges(in file: File) -> [NSRange] {
        return violationRanges(in: file, dictionary: file.structure.dictionary).sorted { $0.location < $1.location }
    }

    private func violationRanges(in file: File,
                                 dictionary: [String: SourceKitRepresentable]) -> [NSRange] {
        return dictionary.substructure.flatMap { subDict -> [NSRange] in
            guard
                let kindString = subDict.kind,
                let kind = SwiftExpressionKind(rawValue: kindString) else { return [] }

            return violationRanges(in: file, dictionary: subDict) +
                violationRanges(in: file, kind: kind, dictionary: subDict)
        }
    }

    private func violationRanges(in file: File,
                                 kind: SwiftExpressionKind,
                                 dictionary: [String: SourceKitRepresentable]) -> [NSRange] {
        guard
            // is it calling a method '.joined' and passing a single argument?
            kind == .call,
            dictionary.name?.hasSuffix(".joined") == true,
            dictionary.enclosedArguments.count == 1
            else { return [] }

        guard
            // is this single argument called 'separator'?
            let argument = dictionary.enclosedArguments.first,
            let offset = argument.offset,
            let length = argument.length,
            argument.name == "separator"
            else { return [] }

        guard
            // is this single argument the default parameter?
            let bodyOffset = argument.bodyOffset,
            let bodyLength = argument.bodyLength,
            let body = file.contents.bridge().substringWithByteRange(start: bodyOffset, length: bodyLength),
            body == "\"\""
            else { return [] }

        guard
            let range = file.contents.bridge().byteRangeToNSRange(start: offset, length: length)
            else { return [] }

        return [range]
    }
}
