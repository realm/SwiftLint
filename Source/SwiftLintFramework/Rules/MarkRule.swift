//
//  MarkRule.swift
//  SwiftLint
//
//  Created by Krzysztof Rodak on 22/08/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import SourceKittenFramework

public struct MarkRule: CorrectableRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.Warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "mark",
        name: "Mark",
        description: "MARK comment should be in valid format.",
        nonTriggeringExamples: [
            "// MARK: good",
            "// MARK: - good",
            "// MARK: -"
        ],
        triggeringExamples: [
            "//MARK: bad",
            "// MARK:bad",
            "//MARK:bad",
            "//  MARK: bad",
            "// MARK:  bad",
            "// MARK: -bad",
            "// MARK:- bad",
            "// MARK:-bad",
            "//MARK: - bad",
            "//MARK:- bad",
            "//MARK: -bad",
            "//MARK:-bad"
        ],
        corrections: [
            "//MARK: comment"   : "// MARK: comment",
            "// MARK:  comment"   : "// MARK: comment",
            "// MARK:comment" : "// MARK: comment",
            "//  MARK: comment" : "// MARK: comment",
            "//MARK: - comment" : "// MARK: - comment",
            "// MARK:- comment" : "// MARK: - comment",
            "// MARK: -comment" : "// MARK: - comment"
        ]
    )

    private let nonSpace = "[^ ]"
    private let twoOrMoreSpace = " {2,}"
    private let mark = "MARK:"

    private var nonSpaceOrTwoOrMoreSpace: String {
        return "(\(nonSpace)|\(twoOrMoreSpace))"
    }

    private var spaceStartPattern: String {
        return "(\(nonSpaceOrTwoOrMoreSpace)\(mark))"
    }

    private var endNonSpacePattern: String {
        return "(\(mark)\(nonSpace))"
    }

    private var endTwoOrMoreSpacePattern: String {
        return "(\(mark)\(twoOrMoreSpace))"
    }

    private var twoOrMoreSpacesAfterHyphenPattern: String {
        return "(\(mark) -\(twoOrMoreSpace))"
    }

    private var nonSpaceAfterHyphenPattern: String {
        return "(\(mark) -\(nonSpace))"
    }

    private var pattern: String {
        return [
            spaceStartPattern,
            endNonSpacePattern,
            endTwoOrMoreSpacePattern,
            twoOrMoreSpacesAfterHyphenPattern,
            nonSpaceAfterHyphenPattern
        ].joinWithSeparator("|")
    }

    public func validateFile(file: File) -> [StyleViolation] {
        return violationRangesInFile(file, withPattern: pattern).map {
            StyleViolation(ruleDescription: self.dynamicType.description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func correctFile(file: File) -> [Correction] {
        var result = [Correction]()

        result.appendContentsOf(correctFile(file,
            pattern: spaceStartPattern,
            replaceString: "// MARK:"))

        result.appendContentsOf(correctFile(file,
            pattern: endNonSpacePattern,
            replaceString: "// MARK: ",
            keepLastChar: true))

        result.appendContentsOf(correctFile(file,
            pattern: endTwoOrMoreSpacePattern,
            replaceString: "// MARK: "))

        result.appendContentsOf(correctFile(file,
            pattern: twoOrMoreSpacesAfterHyphenPattern,
            replaceString: "// MARK: - "))

        result.appendContentsOf(correctFile(file,
            pattern: nonSpaceAfterHyphenPattern,
            replaceString: "// MARK: - ",
            keepLastChar: true))

        return result
    }

    private func correctFile(file: File,
                             pattern: String,
                             replaceString: String,
                             keepLastChar: Bool = false) -> [Correction] {
        let violations = violationRangesInFile(file, withPattern: pattern)
        let matches = file.ruleEnabledViolatingRanges(violations, forRule: self)
        if matches.isEmpty { return [] }

        var nsstring = file.contents as NSString
        let description = self.dynamicType.description
        var corrections = [Correction]()
        for var range in matches.reverse() {
            if keepLastChar {
                range.length -= 1
            }
            let location = Location(file: file, characterOffset: range.location)
            nsstring = nsstring.stringByReplacingCharactersInRange(range, withString: replaceString)
            corrections.append(Correction(ruleDescription: description, location: location))
        }
        file.write(nsstring as String)
        file.invalidateCache()
        return corrections
    }

    private func violationRangesInFile(file: File, withPattern pattern: String) -> [NSRange] {
        let nsstring = file.contents as NSString
        return file.rangesAndTokensMatching(pattern).filter { range, syntaxTokens in
            let syntaxKinds = syntaxTokens.flatMap { SyntaxKind(rawValue: $0.type) }
            return syntaxKinds.startsWith([.Comment])
        }.flatMap { range, syntaxTokens in
            let identifierRange = nsstring
                .byteRangeToNSRange(start: syntaxTokens[0].offset, length: 0)
            return identifierRange.map { NSUnionRange($0, range) }
        }
    }
}
