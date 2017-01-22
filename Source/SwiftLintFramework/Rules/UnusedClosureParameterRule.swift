//
//  UnusedClosureParameterRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/15/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct UnusedClosureParameterRule: ASTRule, ConfigurationProviderRule, CorrectableRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "unused_closure_parameter",
        name: "Unused Closure Parameter",
        description: "Unused parameter in a closure should be replaced with _.",
        nonTriggeringExamples: [
            "[1, 2].map { $0 + 1 }\n",
            "[1, 2].map({ $0 + 1 })\n",
            "[1, 2].map { number in\n number + 1 \n}\n",
            "[1, 2].map { _ in\n 3 \n}\n",
            "[1, 2].something { number, idx in\n return number * idx\n}\n",
            "let isEmpty = [1, 2].isEmpty()\n",
            "violations.sorted(by: { lhs, rhs in \n return lhs.location > rhs.location\n})\n",
            "rlmConfiguration.migrationBlock.map { rlmMigration in\n" +
                "return { migration, schemaVersion in\n" +
                "rlmMigration(migration.rlmMigration, schemaVersion)\n" +
                "}\n" +
            "}"
        ],
        triggeringExamples: [
            "[1, 2].map { ↓number in\n return 3\n}\n",
            "[1, 2].map { ↓number in\n return numberWithSuffix\n}\n",
            "[1, 2].map { ↓number in\n return 3 // number\n}\n",
            "[1, 2].map { ↓number in\n return 3 \"number\"\n}\n",
            "[1, 2].something { number, ↓idx in\n return number\n}\n"
        ],
        corrections: [
            "[1, 2].map { ↓number in\n return 3\n}\n":
                "[1, 2].map { _ in\n return 3\n}\n",
            "[1, 2].map { ↓number in\n return numberWithSuffix\n}\n":
                "[1, 2].map { _ in\n return numberWithSuffix\n}\n",
            "[1, 2].map { ↓number in\n return 3 // number\n}\n":
                "[1, 2].map { _ in\n return 3 // number\n}\n",
            "[1, 2].map { ↓number in\n return 3 \"number\"\n}\n":
                "[1, 2].map { _ in\n return 3 \"number\"\n}\n",
            "[1, 2].something { number, ↓idx in\n return number\n}\n":
                "[1, 2].something { number, _ in\n return number\n}\n"
        ]
    )

    public func validate(file: File, kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        return violationRanges(in: file, dictionary: dictionary, kind: kind).map { range, name in
            let reason = "Unused parameter \"\(name)\" in a closure should be replaced with _."
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, characterOffset: range.location),
                                  reason: reason)
        }
    }

    private func violationRanges(in file: File, dictionary: [String: SourceKitRepresentable],
                                 kind: SwiftExpressionKind) -> [(range: NSRange, name: String)] {
        guard kind == .call,
            let offset = dictionary.offset,
            let length = dictionary.length,
            let nameOffset = dictionary.nameOffset,
            let nameLength = dictionary.nameLength,
            let bodyLength = dictionary.bodyLength,
            bodyLength > 0 else {
                return []
        }

        let rangeStart = nameOffset + nameLength
        let rangeLength = (offset + length) - (nameOffset + nameLength)
        let parameters = dictionary.enclosedVarParameters
        let contents = file.contents.bridge()

        return parameters.flatMap { param -> (NSRange, String)? in
            guard let paramOffset = param.offset,
                let paramLength = param.length,
                let name = param[nameKey(for: .current)] as? String,
                name != "_",
                let regex = try? NSRegularExpression(pattern: name,
                                                     options: [.ignoreMetacharacters]),
                let range = contents.byteRangeToNSRange(start: rangeStart, length: rangeLength)
            else {
                return nil
            }

            let matches = regex.matches(in: file.contents, options: [], range: range).ranges()
            for range in matches {
                guard let byteRange = contents.NSRangeToByteRange(start: range.location,
                                                                  length: range.length),
                    // if it's the parameter declaration itself, we should skip
                    byteRange.location != paramOffset,
                    case let tokens = file.syntaxMap.tokens(inByteRange: byteRange),
                    // a parameter usage should be only one token
                    tokens.count == 1 else {
                    continue
                }

                // found a usage, there's no violation!
                if let token = tokens.first, SyntaxKind(rawValue: token.type) == .identifier,
                    token.offset == byteRange.location, token.length == byteRange.length {
                    return nil
                }
            }
            if let range = contents.byteRangeToNSRange(start: paramOffset, length: paramLength) {
                return (range, name)
            }
            return nil
        }
    }

    private func nameKey(for version: SwiftVersion) -> String {
        switch version {
        case .two: return "key.typename"
        case .three: return "key.name"
        }
    }

    private func violationRanges(in file: File,
                                 dictionary: [String: SourceKitRepresentable]) -> [NSRange] {
        return dictionary.substructure.flatMap { subDict -> [NSRange] in
            guard let kindString = subDict.kind,
                let kind = SwiftExpressionKind(rawValue: kindString) else {
                    return []
            }
            return violationRanges(in: file, dictionary: subDict) +
                violationRanges(in: file, dictionary: subDict, kind: kind).map({ $0.0 })
        }
    }

    private func violationRanges(in file: File) -> [NSRange] {
        return violationRanges(in: file, dictionary: file.structure.dictionary).sorted { lh, rh in
            lh.location < rh.location
        }
    }

    public func correct(file: File) -> [Correction] {
        let violatingRanges = file.ruleEnabled(violatingRanges: violationRanges(in: file), for: self)
        var correctedContents = file.contents
        var adjustedLocations = [Int]()

        for violatingRange in violatingRanges.reversed() {
            if let indexRange = correctedContents.nsrangeToIndexRange(violatingRange) {
                correctedContents = correctedContents
                    .replacingCharacters(in: indexRange, with: "_")
                adjustedLocations.insert(violatingRange.location, at: 0)
            }
        }

        file.write(correctedContents)

        return adjustedLocations.map {
            Correction(ruleDescription: type(of: self).description,
                       location: Location(file: file, characterOffset: $0))
        }
    }
}
