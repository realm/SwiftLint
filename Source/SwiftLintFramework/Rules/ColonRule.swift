//
//  ColonRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ColonRule: CorrectableRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.Warning)

    public init() {}

    public var flexibleRightSpacing = false

    public init(configuration: AnyObject) throws {
        flexibleRightSpacing = configuration["flexible_right_spacing"] as? Bool == true
    }

    public var configurationDescription: String {
        return "flexible_right_spacing: \(flexibleRightSpacing)"
    }

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
            "// 周斌佳年周斌佳\nlet abc: String = \"abc:\""
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
            "func abc(def: Void, ↓ghi :Void) {}\n"
        ],
        corrections: [
            "let abc:Void\n": "let abc: Void\n",
            "let abc:  Void\n": "let abc: Void\n",
            "let abc :Void\n": "let abc: Void\n",
            "let abc : Void\n": "let abc: Void\n",
            "let abc : [Void: Void]\n": "let abc: [Void: Void]\n",
            "let abc : (Void, String, Int)\n": "let abc: (Void, String, Int)\n",
            "let abc : ([Void], String, Int)\n": "let abc: ([Void], String, Int)\n",
            "let abc : [([Void], String, Int)]\n": "let abc: [([Void], String, Int)]\n",
            "let abc:  (Void, String, Int)\n": "let abc: (Void, String, Int)\n",
            "let abc:  ([Void], String, Int)\n": "let abc: ([Void], String, Int)\n",
            "let abc:  [([Void], String, Int)]\n": "let abc: [([Void], String, Int)]\n",
            "let abc :String=\"def\"\n": "let abc: String=\"def\"\n",
            "let abc :Int=0\n": "let abc: Int=0\n",
            "let abc :Int = 0\n": "let abc: Int = 0\n",
            "let abc:Int=0\n": "let abc: Int=0\n",
            "let abc:Int = 0\n": "let abc: Int = 0\n",
            "let abc:Enum=Enum.Value\n": "let abc: Enum=Enum.Value\n",
            "func abc(def:Void) {}\n": "func abc(def: Void) {}\n",
            "func abc(def:  Void) {}\n": "func abc(def: Void) {}\n",
            "func abc(def :Void) {}\n": "func abc(def: Void) {}\n",
            "func abc(def : Void) {}\n": "func abc(def: Void) {}\n",
            "func abc(def: Void, ghi :Void) {}\n": "func abc(def: Void, ghi: Void) {}\n"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        return violationRangesInFile(file, withPattern: pattern).flatMap { range in
            return StyleViolation(ruleDescription: self.dynamicType.description,
                                  severity: configuration.severity,
                                  location: Location(file: file, characterOffset: range.location))
        }
    }

    public func correctFile(file: File) -> [Correction] {
        let matches = violationRangesInFile(file, withPattern: pattern)
        guard !matches.isEmpty else { return [] }

        let regularExpression = regex(pattern)
        let description = self.dynamicType.description
        var corrections = [Correction]()
        var contents = file.contents
        for range in matches.reverse() {
            contents = regularExpression.stringByReplacingMatchesInString(contents,
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
        let spacingRegex = flexibleRightSpacing ? "(?:\\s{0})" : "(?:\\s{0}|\\s{2,})"

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

    private func violationRangesInFile(file: File, withPattern pattern: String) -> [NSRange] {
        let nsstring = file.contents as NSString
        let commentAndStringKindsSet = Set(SyntaxKind.commentAndStringKinds())
        return file.rangesAndTokensMatching(pattern).filter { range, syntaxTokens in
            let syntaxKinds = syntaxTokens.flatMap { SyntaxKind(rawValue: $0.type) }
            if !syntaxKinds.startsWith([.Identifier, .Typeidentifier]) {
                return false
            }
            return Set(syntaxKinds).intersect(commentAndStringKindsSet).isEmpty
        }.flatMap { range, syntaxTokens in
            let identifierRange = nsstring // swiftlint:disable:next force_unwrapping
                .byteRangeToNSRange(start: syntaxTokens.first!.offset, length: 0)
            return identifierRange.map { NSUnionRange($0, range) }
        }
    }
}
