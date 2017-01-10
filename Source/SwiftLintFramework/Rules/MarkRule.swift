//
//  MarkRule.swift
//  SwiftLint
//
//  Created by Krzysztof Rodak on 08/22/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct MarkRule: CorrectableRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "mark",
        name: "Mark",
        description: "MARK comment should be in valid format.",
        nonTriggeringExamples: [
            "// MARK: good\n",
            "// MARK: - good\n",
            "// MARK: -\n"
        ],
        triggeringExamples: [
            "↓//MARK: bad",
            "↓// MARK:bad",
            "↓//MARK:bad",
            "↓//  MARK: bad",
            "↓// MARK:  bad",
            "↓// MARK: -bad",
            "↓// MARK:- bad",
            "↓// MARK:-bad",
            "↓//MARK: - bad",
            "↓//MARK:- bad",
            "↓//MARK: -bad",
            "↓//MARK:-bad"
        ],
        corrections: [
            "↓//MARK: comment": "// MARK: comment",
            "↓// MARK:  comment": "// MARK: comment",
            "↓// MARK:comment": "// MARK: comment",
            "↓//  MARK: comment": "// MARK: comment",
            "↓//MARK: - comment": "// MARK: - comment",
            "↓// MARK:- comment": "// MARK: - comment",
            "↓// MARK: -comment": "// MARK: - comment"
        ]
    )

    private let nonSpace = "[^ ]"
    private let twoOrMoreSpace = " {2,}"
    private let mark = "MARK:"

    private var nonSpaceOrTwoOrMoreSpace: String {
        return "(?:\(nonSpace)|\(twoOrMoreSpace))"
    }

    private var spaceStartPattern: String {
        return "(?:\(nonSpaceOrTwoOrMoreSpace)\(mark))"
    }

    private var endNonSpacePattern: String {
        return "(?:\(mark)\(nonSpace))"
    }

    private var endTwoOrMoreSpacePattern: String {
        return "(?:\(mark)\(twoOrMoreSpace))"
    }

    private var twoOrMoreSpacesAfterHyphenPattern: String {
        return "(?:\(mark) -\(twoOrMoreSpace))"
    }

    private var nonSpaceOrNewlineAfterHyphenPattern: String {
        return "(?:\(mark) -[^ \n])"
    }

    private var pattern: String {
        return [
            spaceStartPattern,
            endNonSpacePattern,
            endTwoOrMoreSpacePattern,
            twoOrMoreSpacesAfterHyphenPattern,
            nonSpaceOrNewlineAfterHyphenPattern
        ].joined(separator: "|")
    }

    public func validate(file: File) -> [StyleViolation] {
        return violationRanges(in: file, matching: pattern).map {
            StyleViolation(ruleDescription: type(of: self).description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func correct(file: File) -> [Correction] {
        var result = [Correction]()

        result.append(contentsOf: correct(file: file,
            pattern: spaceStartPattern,
            replaceString: "// MARK:"))

        result.append(contentsOf: correct(file: file,
            pattern: endNonSpacePattern,
            replaceString: "// MARK: ",
            keepLastChar: true))

        result.append(contentsOf: correct(file: file,
            pattern: endTwoOrMoreSpacePattern,
            replaceString: "// MARK: "))

        result.append(contentsOf: correct(file: file,
            pattern: twoOrMoreSpacesAfterHyphenPattern,
            replaceString: "// MARK: - "))

        result.append(contentsOf: correct(file: file,
            pattern: nonSpaceOrNewlineAfterHyphenPattern,
            replaceString: "// MARK: - ",
            keepLastChar: true))

        return result
    }

    private func correct(file: File,
                         pattern: String,
                         replaceString: String,
                         keepLastChar: Bool = false) -> [Correction] {
        let violations = violationRanges(in: file, matching: pattern)
        let matches = file.ruleEnabled(violatingRanges: violations, for: self)
        if matches.isEmpty { return [] }

        var nsstring = file.contents.bridge()
        let description = type(of: self).description
        var corrections = [Correction]()
        for var range in matches.reversed() {
            if keepLastChar {
                range.length -= 1
            }
            let location = Location(file: file, characterOffset: range.location)
            nsstring = nsstring.replacingCharacters(in: range, with: replaceString).bridge()
            corrections.append(Correction(ruleDescription: description, location: location))
        }
        file.write(nsstring.bridge())
        return corrections
    }

    private func violationRanges(in file: File, matching pattern: String) -> [NSRange] {
        let nsstring = file.contents.bridge()
        return file.rangesAndTokens(matching: pattern).filter { _, syntaxTokens in
            return !syntaxTokens.isEmpty && SyntaxKind(rawValue: syntaxTokens[0].type) == .comment
        }.flatMap { range, syntaxTokens in
            let identifierRange = nsstring
                .byteRangeToNSRange(start: syntaxTokens[0].offset, length: 0)
            return identifierRange.map { NSUnionRange($0, range) }
        }
    }
}
