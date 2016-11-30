//
//  DictionaryColonRule.swift
//  SwiftLint
//

import Foundation
import SourceKittenFramework

public struct DictionaryColonRule: CorrectableRule, OptInRule {

    public var configuration = SeverityConfiguration(.Warning)

    public init() {}

    public init(configuration: AnyObject) throws {
        if let severityString = configuration["severity"] as? String {
            try self.configuration.applyConfiguration(severityString)
        }
    }

    public var configurationDescription: String {
        return configuration.consoleDescription
    }

    public static let description = RuleDescription(
        identifier: "dictionary_colon",
        name: "Dictionary Colon",
        description: "Colons should be next to the key when specifying a dictionary literal or type.", //swiftlint:disable:this line_length
        nonTriggeringExamples: [
            "let abc: [Void: Void]\n",
            "let abc: [Void:\nVoid]\n"
        ],
        triggeringExamples: [
            "let abc: [↓Void : Void]\n",
            "let abc: [↓Void :Void]\n"
        ],
        corrections: [
            "let abc: [Void : Void]\n": "let abc: [Void: Void]\n",
            "let abc: [Void :Void]\n": "let abc: [Void: Void]\n"
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
        let violations = violationRangesInFile(file, withPattern: pattern)
        let matches = file.ruleEnabledViolatingRanges(violations, forRule: self)
        guard !matches.isEmpty else { return [] }
        let regularExpression = regex(pattern)
        let description = self.dynamicType.description
        var corrections = [Correction]()
        var contents = file.contents
        for range in matches.reverse() {
            let location = Location(file: file, characterOffset: range.location)
            contents = regularExpression.stringByReplacingMatchesInString(contents,
                    options: [], range: range, withTemplate: "$1: $2")
            corrections.append(Correction(ruleDescription: description, location: location))
        }
        file.write(contents)
        return corrections
    }

    // MARK: - Private

    private var pattern: String {
        return "(\\w)" +            // Capture an identifier
            "(?:" +                 // start group
            "\\s+" +                // followed by whitespace
            ":" +                   // to the left of a colon
            "\\s*" +                // followed by any amount of whitespace.
            "|" +                   // or
            ":" +                   // immediately followed by a colon
            "(?:\\s{0}|\\s{2,})" +  // followed by 0 or 2+ spaces
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
            return Set(syntaxKinds).intersect(commentAndStringKindsSet).isEmpty
            }.flatMap { range, syntaxTokens in
                let identifierRange = nsstring
                    .byteRangeToNSRange(start: syntaxTokens[0].offset, length: 0)
                return identifierRange.map { NSUnionRange($0, range) }
        }
    }
}
