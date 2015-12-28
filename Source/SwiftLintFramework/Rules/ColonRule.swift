//
//  ColonRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct ColonRule: CorrectableRule {
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
        let pattern = patterns().joinWithSeparator("|")

        return violationRangesInFile(file, withPattern: pattern).flatMap { range in
            return StyleViolation(ruleDescription: self.dynamicType.description,
                location: Location(file: file, characterOffset: range.location))
        }
    }

    public func correctFile(file: File) -> [Correction] {
        // Do not join the patterns when correcting, we need 2 explicit capture groups.
        return patterns().reduce([Correction]()) { corrections, pattern in
            return corrections + correctFile(file, withPattern: pattern)
        }
    }

    // MARK: - Private Methods

    private func patterns() -> [String] {
        let spacingLeftOfColonPattern = "" +
            // Capture an identifier
            "(\\w+)" +
            // followed by whitespace
            "\\s+" +
            // to the left of a colon
            ":" +
            // followed by any amount of whitespace.
            "\\s*" +
            // Capture a type identifier
            "(" +
            // which may begin with a series of nested parenthesis or brackets
            "(?:\\[|\\()*" +
            // lazily to the first non-whitespace character.
            "\\S+?)"
        let spacingRightOfColonPattern = "" +
            // Capture an identifier
            "(\\w+)" +
            // immediately followed by a colon
            ":" +
            // followed by 0 or 2+ whitespace characters.
            "(?:\\s{0}|\\s{2,})" +
            // Capture a type identifier
            "(" +
            // which may begin with a series of nested parenthesis or brackets
            "(?:\\[|\\()*" +
            // lazily to the first non-whitespace character.
            "\\S+?)"
        return [spacingLeftOfColonPattern, spacingRightOfColonPattern]
    }

    private func violationRangesInFile(file: File, withPattern pattern: String) -> [NSRange] {
        return file.matchPattern(pattern).filter { range, syntaxKinds in
            if !syntaxKinds.startsWith([.Identifier, .Typeidentifier]) {
                return false
            }

            if Set(syntaxKinds).intersect(Set(SyntaxKind.commentAndStringKinds())).count > 0 {
                return false
            }

            return true
        }.flatMap { $0.0 }
    }

    private func correctFile(file: File, withPattern pattern: String) -> [Correction] {
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
}
