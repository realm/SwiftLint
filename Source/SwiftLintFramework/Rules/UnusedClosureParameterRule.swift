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
            "}",
            "genericsFunc { (a: Type, b) in\n" +
                "a + b\n" +
            "}\n",
            "var label: UILabel = { (lbl: UILabel) -> UILabel in\n" +
            "   lbl.backgroundColor = .red\n" +
            "   return lbl\n" +
            "}(UILabel())\n",
            "hoge(arg: num) { num in\n" +
            "  return num\n" +
            "}\n"
        ],
        triggeringExamples: [
            "[1, 2].map { ↓number in\n return 3\n}\n",
            "[1, 2].map { ↓number in\n return numberWithSuffix\n}\n",
            "[1, 2].map { ↓number in\n return 3 // number\n}\n",
            "[1, 2].map { ↓number in\n return 3 \"number\"\n}\n",
            "[1, 2].something { number, ↓idx in\n return number\n}\n",
            "genericsFunc { (↓number: TypeA, idx: TypeB) in return idx\n}\n",
            "hoge(arg: num) { ↓num in\n" +
            "}\n"
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
                "[1, 2].something { number, _ in\n return number\n}\n",
            "genericsFunc(closure: { (↓int: Int) -> Void in // do something\n}\n":
                "genericsFunc(closure: { (_: Int) -> Void in // do something\n}\n",
            "genericsFunc { (↓a, ↓b: Type) -> Void in\n}\n":
                "genericsFunc { (_, _: Type) -> Void in\n}\n",
            "genericsFunc { (↓a: Type, ↓b: Type) -> Void in\n}\n":
                "genericsFunc { (_: Type, _: Type) -> Void in\n}\n",
            "genericsFunc { (↓a: Type, ↓b) -> Void in\n}\n":
                "genericsFunc { (_: Type, _) -> Void in\n}\n",
            "genericsFunc { (a: Type, ↓b) -> Void in\nreturn a\n}\n":
                "genericsFunc { (a: Type, _) -> Void in\nreturn a\n}\n",
            "hoge(arg: num) { ↓num in\n}\n":
                "hoge(arg: num) { _ in\n}\n"
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
            !isClosure(dictionary: dictionary),
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
                let name = param.name,
                name != "_",
                let regex = try? NSRegularExpression(pattern: name,
                                                     options: [.ignoreMetacharacters]),
                let range = contents.byteRangeToNSRange(start: rangeStart, length: rangeLength)
            else {
                return nil
            }

            let paramLength = name.bridge().length

            let matches = regex.matches(in: file.contents, options: [], range: range).ranges()
            for range in matches {
                guard let byteRange = contents.NSRangeToByteRange(start: range.location,
                                                                  length: range.length),
                    // if it's the parameter declaration itself, we should skip
                    byteRange.location > paramOffset,
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

    private func isClosure(dictionary: [String: SourceKitRepresentable]) -> Bool {
        return dictionary.name.flatMap { name -> Bool in
            let length = name.bridge().length
            let range = NSRange(location: 0, length: length)
            return regex("\\A\\s*\\{").firstMatch(in: name, options: [], range: range) != nil
        } ?? false
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
        return violationRanges(in: file, dictionary: file.structure.dictionary).sorted { lhs, rhs in
            lhs.location < rhs.location
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
