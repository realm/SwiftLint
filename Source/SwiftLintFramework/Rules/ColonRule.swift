//
//  ColonRule.swift
//  SwiftLint
//
//  Created by JP Simard on 5/16/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ColonRule: ASTRule, CorrectableRule, ConfigurationProviderRule {

    public var configuration = ColonConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "colon",
        name: "Colon",
        description: "Colons should be next to the identifier when specifying a type.",
        nonTriggeringExamples: [
            "let abc: Void\n",
            "let abc: [Void: Void]\n",
            "let abc: (Void, Void)\n",
            "let abc: ([Void], String, Int)\n",
            "let abc: [([Void], String, Int)]\n",
            "let abc: String=\"def\"\n",
            "let abc: Int=0\n",
            "let abc: Enum=Enum.Value\n",
            "func abc(def: Void) {}\n",
            "func abc(def: Void, ghi: Void) {}\n",
            "// 周斌佳年周斌佳\nlet abc: String = \"abc:\"",
            "let abc = [Void: Void]()\n",
            "let abc = [1: [3: 2], 3: 4]\n"
        ],
        triggeringExamples: [
            "let ↓abc:Void\n",
            "let ↓abc:  Void\n",
            "let ↓abc :Void\n",
            "let ↓abc : Void\n",
            "let ↓abc : [Void: Void]\n",
            "let ↓abc : (Void, String, Int)\n",
            "let ↓abc : ([Void], String, Int)\n",
            "let ↓abc : [([Void], String, Int)]\n",
            "let ↓abc:  (Void, String, Int)\n",
            "let ↓abc:  ([Void], String, Int)\n",
            "let ↓abc:  [([Void], String, Int)]\n",
            "let ↓abc :String=\"def\"\n",
            "let ↓abc :Int=0\n",
            "let ↓abc :Int = 0\n",
            "let ↓abc:Int=0\n",
            "let ↓abc:Int = 0\n",
            "let ↓abc:Enum=Enum.Value\n",
            "func abc(↓def:Void) {}\n",
            "func abc(↓def:  Void) {}\n",
            "func abc(↓def :Void) {}\n",
            "func abc(↓def : Void) {}\n",
            "func abc(def: Void, ↓ghi :Void) {}\n",
            "let abc = [Void↓:Void]()\n",
            "let abc = [Void↓ : Void]()\n",
            "let abc = [Void↓:  Void]()\n",
            "let abc = [Void↓ :  Void]()\n",
            "let abc = [1: [3↓ : 2], 3: 4]\n",
            "let abc = [1: [3↓ : 2], 3↓:  4]\n"
        ],
        corrections: [
            "let ↓abc:Void\n": "let abc: Void\n",
            "let ↓abc:  Void\n": "let abc: Void\n",
            "let ↓abc :Void\n": "let abc: Void\n",
            "let ↓abc : Void\n": "let abc: Void\n",
            "let ↓abc : [Void: Void]\n": "let abc: [Void: Void]\n",
            "let ↓abc : (Void, String, Int)\n": "let abc: (Void, String, Int)\n",
            "let ↓abc : ([Void], String, Int)\n": "let abc: ([Void], String, Int)\n",
            "let ↓abc : [([Void], String, Int)]\n": "let abc: [([Void], String, Int)]\n",
            "let ↓abc:  (Void, String, Int)\n": "let abc: (Void, String, Int)\n",
            "let ↓abc:  ([Void], String, Int)\n": "let abc: ([Void], String, Int)\n",
            "let ↓abc:  [([Void], String, Int)]\n": "let abc: [([Void], String, Int)]\n",
            "let ↓abc :String=\"def\"\n": "let abc: String=\"def\"\n",
            "let ↓abc :Int=0\n": "let abc: Int=0\n",
            "let ↓abc :Int = 0\n": "let abc: Int = 0\n",
            "let ↓abc:Int=0\n": "let abc: Int=0\n",
            "let ↓abc:Int = 0\n": "let abc: Int = 0\n",
            "let ↓abc:Enum=Enum.Value\n": "let abc: Enum=Enum.Value\n",
            "func abc(↓def:Void) {}\n": "func abc(def: Void) {}\n",
            "func abc(↓def:  Void) {}\n": "func abc(def: Void) {}\n",
            "func abc(↓def :Void) {}\n": "func abc(def: Void) {}\n",
            "func abc(↓def : Void) {}\n": "func abc(def: Void) {}\n",
            "func abc(def: Void, ↓ghi :Void) {}\n": "func abc(def: Void, ghi: Void) {}\n"
        ]
    )

    public func validateFile(_ file: File) -> [StyleViolation] {
        let violations = violationRangesInFile(file, withPattern: pattern).flatMap { range in
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severityConfiguration.severity,
                                  location: Location(file: file, characterOffset: range.location))
        }

        let dictionaryViolations: [StyleViolation]
        if configuration.applyToDictionaries {
            dictionaryViolations = validateFile(file, dictionary: file.structure.dictionary)
        } else {
            dictionaryViolations = []
        }

        return (violations + dictionaryViolations).sorted { $0.location < $1.location }
    }

    public func validateFile(_ file: File, kind: SwiftExpressionKind,
                             dictionary: [String : SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .dictionary,
            let ranges = colonRanges(dictionary) else {
            return []
        }

        let contents = file.contents.bridge()
        let violations = ranges.filter {
            guard let colon = contents.substringWithByteRange(start: $0.location,
                                                              length: $0.length) else {
                return false
            }

            if configuration.flexibleRightSpacing {
                let isCorrect = colon.hasPrefix(": ") || colon.hasPrefix(":\n")
                return !isCorrect
            }

            return colon != ": " && !colon.hasPrefix(":\n")
        }

        return violations.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severityConfiguration.severity,
                           location: Location(file: file, byteOffset: $0.location))
        }
    }

    public func correctFile(_ file: File) -> [Correction] {
        let violations = violationRangesInFile(file, withPattern: pattern)
        let matches = file.ruleEnabledViolatingRanges(violations, forRule: self)
        guard !matches.isEmpty else { return [] }
        let regularExpression = regex(pattern)
        let description = type(of: self).description
        var corrections = [Correction]()
        var contents = file.contents
        for range in matches.reversed() {
            contents = regularExpression.stringByReplacingMatches(in: contents,
                options: [], range: range, withTemplate: "$1: $2")
            let location = Location(file: file, characterOffset: range.location)
            corrections.append(Correction(ruleDescription: description, location: location))
        }
        file.write(contents)
        return corrections
    }

    // MARK: - Private

    private var pattern: String {
        // If flexible_right_spacing is true, match only 0 whitespaces.
        // If flexible_right_spacing is false or omitted, match 0 or 2+ whitespaces.
        let spacingRegex = configuration.flexibleRightSpacing ? "(?:\\s{0})" : "(?:\\s{0}|\\s{2,})"

        return  "(\\w)" +       // Capture an identifier
                "(?:" +         // start group
                "\\s+" +        // followed by whitespace
                ":" +           // to the left of a colon
                "\\s*" +        // followed by any amount of whitespace.
                "|" +           // or
                ":" +           // immediately followed by a colon
                spacingRegex +  // followed by right spacing regex
                ")" +           // end group
                "(" +           // Capture a type identifier
                "[\\[|\\(]*" +  // which may begin with a series of nested parenthesis or brackets
                "\\S)"          // lazily to the first non-whitespace character.
    }

    private func violationRangesInFile(_ file: File, withPattern pattern: String) -> [NSRange] {
        let nsstring = file.contents.bridge()
        let commentAndStringKindsSet = Set(SyntaxKind.commentAndStringKinds())
        return file.rangesAndTokensMatching(pattern).filter { _, syntaxTokens in
            let syntaxKinds = syntaxTokens.flatMap { SyntaxKind(rawValue: $0.type) }
            if !syntaxKinds.starts(with: [.identifier, .typeidentifier]) {
                return false
            }
            return Set(syntaxKinds).intersection(commentAndStringKindsSet).isEmpty
        }.flatMap { range, syntaxTokens in
            let identifierRange = nsstring
                .byteRangeToNSRange(start: syntaxTokens[0].offset, length: 0)
            return identifierRange.map { NSUnionRange($0, range) }
        }
    }

    private func colonRanges(_ dictionary: [String: SourceKitRepresentable]) -> [NSRange]? {
        guard let elements = dictionary["key.elements"] as? [SourceKitRepresentable],
            elements.count % 2 == 0 else {
            return nil
        }

        let expectedKind = "source.lang.swift.structure.elem.expr"
        let ranges: [NSRange] = elements.flatMap {
            guard let subDict = $0 as? [String: SourceKitRepresentable],
                subDict["key.kind"] as? String == expectedKind,
                let offset = (subDict["key.offset"] as? Int64).map({ Int($0) }),
                let length = (subDict["key.length"] as? Int64).map({ Int($0) }) else {
                    return nil
            }

            return NSRange(location: offset, length: length)
        }

        let even = ranges.enumerated().flatMap { $0 % 2 == 0 ? $1 : nil }
        let odd = ranges.enumerated().flatMap { $0 % 2 != 0 ? $1 : nil }

        return zip(even, odd).map { range1, range2 -> NSRange in
            let location = NSMaxRange(range1)
            let length = range2.location - location

            return NSRange(location: location, length: length)
        }
    }
}
