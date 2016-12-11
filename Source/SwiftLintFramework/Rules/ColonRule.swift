//
//  ColonRule.swift
//  SwiftLint
//
//  Created by JP Simard on 5/16/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ColonRule: CorrectableRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public var flexibleRightSpacing = false

    public init(configuration: Any) throws {
        let dictionary = configuration as? [String:Any]
        if let severityString = dictionary?["severity"] as? String {
            try self.configuration.applyConfiguration(severityString)
        }

        flexibleRightSpacing = dictionary?["flexible_right_spacing"] as? Bool == true
    }

    public var configurationDescription: String {
        return configuration.consoleDescription +
            ", flexible_right_spacing: \(flexibleRightSpacing)"
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

    public func validateFile(_ file: File) -> [StyleViolation] {
        return violationRangesInFile(file, withPattern: pattern).flatMap { range in
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, characterOffset: range.location))
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

    fileprivate var pattern: String {
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

    fileprivate func violationRangesInFile(_ file: File, withPattern pattern: String) -> [NSRange] {
        let nsstring = file.contents.bridge()
        let commentAndStringKindsSet = Set(SyntaxKind.commentAndStringKinds())
        return file.rangesAndTokensMatching(pattern).filter { range, syntaxTokens in
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
