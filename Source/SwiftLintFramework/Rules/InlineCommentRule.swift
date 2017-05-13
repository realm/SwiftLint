//
//  InlineCommentRule.swift
//  SwiftLint
//
//  Created by Kim de Vos on 05/11/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private let nonSpace = "[^\\s]"
private let nonOrOneSpace = "\\s{0,1}"
private let twoSpace = "\\s{2}"
private let twoOrMoreSpace = "\\s{2,}"
private let threeOrMoreSpace = "\\s{3,}"
private let comment = "//"

public struct InlineCommentRule: ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "inline_comment",
        name: "InlineComment",
        description: "Inline comments should be in valid format.",
        nonTriggeringExamples: [
            "var foo: Bool?  // Good"
        ],
        triggeringExamples: [
        "↓var foo1: Date?  //Wrong",
        "↓var foo2: Date?  //  Wrong",
        "↓var foo3: Date? // Wrong",
        "↓var foo4: Date?// Wrong",
        "↓var foo5: Date?   // Wrong"
        ]
    )

    private let inlineStartPattern = "(?:\\S(?:\(nonOrOneSpace)|\(threeOrMoreSpace))\(comment))"
    private let inlineEndPattern = "(?:\\S\(twoSpace)\(comment)(:?\(nonSpace)|\(twoOrMoreSpace)))"

    private var pattern: String {
        return [
            inlineStartPattern,
            inlineEndPattern
            ].joined(separator: "|")
    }

    public func validate(file: File) -> [StyleViolation] {
        return violationRanges(in: file, matching: pattern).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
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
