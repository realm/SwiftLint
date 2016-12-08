//
//  ColonRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

//swiftlint:disable type_body_length
public struct ColonRule: CorrectableRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public var flexibleRightSpacing = false
    public var applyToDictionaries = false
    private static var _applyToDictionaries = false

    public init(configuration: Any) throws {
        let dictionary = configuration as? [String:Any]
        if let severityString = dictionary?["severity"] as? String {
            try self.configuration.applyConfiguration(severityString)
        }

        flexibleRightSpacing = dictionary?["flexible_right_spacing"] as? Bool == true
        applyToDictionaries = dictionary?["apply_to_dictionaries"] as? Bool == true
        ColonRule._applyToDictionaries = applyToDictionaries
    }

    public var configurationDescription: String {
        return configuration.consoleDescription +
            ", flexible_right_spacing: \(flexibleRightSpacing)" +
        ", apply_to_dictionaries: \(applyToDictionaries)"
    }

    public static var description: RuleDescription {
        let identifier = "colon"
        let name = "Colon"
        let description: String
        if _applyToDictionaries {
            description = "Colons should be next to the identifier when specifying a type or dictionary literal." //swiftlint:disable:this line_length
        } else {
            description = "Colons should be next to the identifier when specifying a type."
        }

        let nonTriggeringExamples: [String]
        if _applyToDictionaries {
            nonTriggeringExamples = [
                "let abc: [Void: Void]\n",
                "let abc: ([Void: Void], [Void: [Void: Void]])\n",
                "let abc: ([Void], String, [Void: Void])\n",
                "let abc: [([Void], [Void: Void], Int)]\n",
                "let abc: String=\"[Void : Void]\"\n",
                "let abc: [String: String] = [\"key\": \"value\"]",
                "let abc: [String: String] = [\"key\": \"value\", \"key1\": \"value1\"]",
                "func abc(def: [Void: Void]) {}\n",
                "func abc(def: Void, ghi: [Void: [Void: [Void: [Void]]]]) {}\n",
                "// 周斌佳年周斌佳\nlet abc: String = \"[Void : Void]\""
            ]
        } else {
            nonTriggeringExamples = [
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
            ]
        }

        let triggeringExamples: [String]
        if _applyToDictionaries {
            triggeringExamples = [
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
                "let abc: [↓Void : Void]\n",
                "let abc: [↓Void :Void]\n",
                "let abc: ([Void: Void], [↓Void :[Void: Void]])\n",
                "let abc: ([Void: Void], [↓Void:[↓Void : Void]])\n",
                "let abc: ([↓Void : Void], [↓Void : [↓Void : Void]])\n",
                "let abc: [String: String] = [↓\"key\" : \"value\"]",
                "let abc: [String: String] = [↓\"key\" :\"value\"]"
            ]
        } else {
            triggeringExamples = [
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
            ]
        }

        let corrections: [String: String]
        if _applyToDictionaries {
            corrections = [
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
                "func abc(def: Void, ghi :Void) {}\n": "func abc(def: Void, ghi: Void) {}\n",
                "let abc: [Void : Void]\n": "let abc: [Void: Void]\n",
                "let abc: [Void :Void]\n": "let abc: [Void: Void]\n",
                "let abc: ([Void: Void], [Void :[Void: Void]])\n": "let abc: ([Void: Void], [Void: [Void: Void]])\n", //swiftlint:disable:this line_length
                "let abc: ([Void : Void], [Void : [Void : Void]])\n": "let abc: ([Void: Void], [Void: [Void: Void]])\n", //swiftlint:disable:this line_length
                "let abc: [String: String] = [\"key\" : \"value\"]": "let abc: [String: String] = [\"key\": \"value\"]", //swiftlint:disable:this line_length
                "let abc: [String: String] = [\"key\" :\"value\", \"key1\" : \"value2\"]": "let abc: [String: String] = [\"key\": \"value\", \"key2\": \"value2\"]"//swiftlint:disable:this line_length
            ]
        } else {
            corrections = [
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
        }

        return RuleDescription(
            identifier: identifier,
            name: name,
            description: description,
            nonTriggeringExamples: nonTriggeringExamples,
            triggeringExamples: triggeringExamples,
            corrections: corrections
        )
    }

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
        let stringKeyIdentifierRegex = applyToDictionaries ? "(\\w|[\"]?)" : "(\\w)"

        return  stringKeyIdentifierRegex +       // Capture an identifier
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
        let nsstring = file.contents as NSString
        let commentAndStringKindsSet = Set(SyntaxKind.commentAndStringKinds())
        return file.rangesAndTokensMatching(pattern).filter { range, syntaxTokens in
            let syntaxKinds = syntaxTokens.flatMap { SyntaxKind(rawValue: $0.type) }
            if applyToDictionaries {
                // When there is a dictionary like this ["key": "value"], source kitten
                // gives us 2 syntax tokens of kind .String. We want to allow these types
                // of dictionaries to be flagged if the colon is incorrect.
                let onlyStringSyntaxKinds = !Set(syntaxKinds).intersection(Set([SyntaxKind.string])).isEmpty //swiftlint:disable:this line_length
                if syntaxKinds.count > 1 && onlyStringSyntaxKinds {
                    return true
                } else {
                    return Set(syntaxKinds).intersection(commentAndStringKindsSet).isEmpty
                }
            } else {
                if !syntaxKinds.starts(with: [.identifier, .typeidentifier]) {
                    return false
                }
            }
            return Set(syntaxKinds).intersection(commentAndStringKindsSet).isEmpty
            }.flatMap { range, syntaxTokens in
                let identifierRange = nsstring
                    .byteRangeToNSRange(start: syntaxTokens[0].offset, length: 0)
                return identifierRange.map { NSUnionRange($0, range) }
        }
    }
}
