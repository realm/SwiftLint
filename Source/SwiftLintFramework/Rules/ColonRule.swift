//
//  ColonRule.swift
//  SwiftLint
//
//  Created by JP Simard on 5/16/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private enum ColonKind {
    case type
    case dictionary
}

public struct ColonRule: ASTRule, CorrectableRule, ConfigurationProviderRule {

    public var configuration = ColonConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "colon",
        name: "Colon",
        description: "Colons should be next to the identifier when specifying a type " +
                     "and next to the key in dictionary literals.",
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
            "let abc = [1: [3: 2], 3: 4]\n",
            "let abc = [\"string\": \"string\"]\n",
            "let abc = [\"string:string\": \"string\"]\n"
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
            "func abc(def: Void, ↓ghi :Void) {}\n": "func abc(def: Void, ghi: Void) {}\n",
            "let abc = [Void↓:Void]()\n": "let abc = [Void: Void]()\n",
            "let abc = [Void↓ : Void]()\n": "let abc = [Void: Void]()\n",
            "let abc = [Void↓:  Void]()\n": "let abc = [Void: Void]()\n",
            "let abc = [Void↓ :  Void]()\n": "let abc = [Void: Void]()\n",
            "let abc = [1: [3↓ : 2], 3: 4]\n": "let abc = [1: [3: 2], 3: 4]\n",
            "let abc = [1: [3↓ : 2], 3↓:  4]\n": "let abc = [1: [3: 2], 3: 4]\n"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let violations = typeColonViolationRanges(in: file, matching: pattern).flatMap { range in
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severityConfiguration.severity,
                                  location: Location(file: file, characterOffset: range.location))
        }

        let dictionaryViolations: [StyleViolation]
        if configuration.applyToDictionaries {
            dictionaryViolations = validate(file: file, dictionary: file.structure.dictionary)
        } else {
            dictionaryViolations = []
        }

        return (violations + dictionaryViolations).sorted { $0.location < $1.location }
    }

    public func correct(file: File) -> [Correction] {
        let violations = correctionRanges(in: file)
        let matches = violations.filter {
            !file.ruleEnabled(violatingRanges: [$0.range], for: self).isEmpty
        }

        guard !matches.isEmpty else { return [] }
        let regularExpression = regex(pattern)
        let description = type(of: self).description
        var corrections = [Correction]()
        var contents = file.contents
        for (range, kind) in matches.reversed() {
            switch kind {
            case .type:
                contents = regularExpression.stringByReplacingMatches(in: contents,
                                                                      options: [],
                                                                      range: range,
                                                                      withTemplate: "$1: $2")
            case .dictionary:
                contents = contents.bridge().replacingCharacters(in: range, with: ": ")
            }

            let location = Location(file: file, characterOffset: range.location)
            corrections.append(Correction(ruleDescription: description, location: location))
        }
        file.write(contents)
        return corrections
    }

    private typealias RangeWithKind = (range: NSRange, kind: ColonKind)

    private func correctionRanges(in file: File) -> [RangeWithKind] {
        let violations = typeColonViolationRanges(in: file, matching: pattern).map {
            (range: $0, kind: ColonKind.type)
        }
        let dictionary = file.structure.dictionary
        let contents = file.contents.bridge()
        let dictViolations: [RangeWithKind] = dictionaryColonViolationRanges(in: file, dictionary: dictionary).flatMap {
            guard let range = contents.byteRangeToNSRange(start: $0.location, length: $0.length) else {
                return nil
            }
            return (range: range, kind: ColonKind.dictionary)
        }

        return (violations + dictViolations).sorted { $0.range.location < $1.range.location }
    }
}

// MARK: Type Colon Rule

extension ColonRule {

    fileprivate var pattern: String {
        // If flexible_right_spacing is true, match only 0 whitespaces.
        // If flexible_right_spacing is false or omitted, match 0 or 2+ whitespaces.
        let spacingRegex = configuration.flexibleRightSpacing ? "(?:\\s{0})" : "(?:\\s{0}|\\s{2,})"

        return "(\\w)" +       // Capture an identifier
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

    fileprivate func typeColonViolationRanges(in file: File, matching pattern: String) -> [NSRange] {
        let nsstring = file.contents.bridge()
        let commentAndStringKindsSet = Set(SyntaxKind.commentAndStringKinds())
        return file.rangesAndTokens(matching: pattern).filter { _, syntaxTokens in
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
}

// MARK: Dictionary Colon Rule

extension ColonRule {

    /// Only returns dictionary colon violations
    public func validate(file: File, kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {

        let ranges = dictionaryColonViolationRanges(in: file, kind: kind, dictionary: dictionary)
        return ranges.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severityConfiguration.severity,
                           location: Location(file: file, byteOffset: $0.location))
        }
    }

    fileprivate func dictionaryColonViolationRanges(in file: File,
                                                    dictionary: [String: SourceKitRepresentable]) -> [NSRange] {
        guard configuration.applyToDictionaries else {
            return []
        }

        return dictionary.substructure.flatMap { subDict -> [NSRange] in
            guard let kindString = subDict.kind,
                let kind = KindType(rawValue: kindString) else {
                    return []
            }
            return dictionaryColonViolationRanges(in: file, dictionary: subDict) +
                dictionaryColonViolationRanges(in: file, kind: kind, dictionary: subDict)
        }
    }

    private func dictionaryColonViolationRanges(in file: File, kind: SwiftExpressionKind,
                                                dictionary: [String: SourceKitRepresentable]) -> [NSRange] {
        guard kind == .dictionary,
            let ranges = colonRanges(dictionary: dictionary) else {
                return []
        }

        let contents = file.contents.bridge()
        return ranges.filter {
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
    }

    private func colonRanges(dictionary: [String: SourceKitRepresentable]) -> [NSRange]? {
        let elements = dictionary.elements
        guard elements.count % 2 == 0 else {
                return nil
        }

        let expectedKind = "source.lang.swift.structure.elem.expr"
        let ranges: [NSRange] = elements.flatMap { subDict in
            guard subDict.kind == expectedKind,
                let offset = subDict.offset,
                let length = subDict.length else {
                    return nil
            }

            return NSRange(location: offset, length: length)
        }

        let even = ranges.enumerated().flatMap { $0 % 2 == 0 ? $1 : nil }
        let odd = ranges.enumerated().flatMap { $0 % 2 != 0 ? $1 : nil }

        return zip(even, odd).map { evenRange, oddRange -> NSRange in
            let location = NSMaxRange(evenRange)
            let length = oddRange.location - location

            return NSRange(location: location, length: length)
        }
    }
}
