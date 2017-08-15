//
//  InlineCommentRule.swift
//  SwiftLint
//
//  Created by Kim de Vos on 05/11/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

private let nonSpace = "(?!\\s)"
private let noNewLine = "(?!\\n)"
private let twoOrMoreSpaces = "\\s{2,}"
private let nonSpaceOrTwoOrMoreSpaces = "(?:\(nonSpace)|\(twoOrMoreSpaces))"
private let comment = "//"
private let endOfStatement = "[{}()?,:;]++\(noNewLine)"

public struct InlineCommentRule: ConfigurationProviderRule, OptInRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "inline_comment",
        name: "InlineComment",
        description: "Inline comments should be in valid format.",
        kind: .lint,
        nonTriggeringExamples: [
            "// Good\nfunc foo() {\n}",
            "func foo() { // Good\n}",
            "class Foo {var foo = Date() // Good\n}",
            "class Foo {var foo: Date? // Good\n}",
            "class Foo {var foo = [1, // Good\n2]\n}"
        ],
        triggeringExamples: [
        "func foo() { ↓//Wrong\n}",
        "func foo() { ↓//  Wrong\n}",
        "func foo() {↓// Wrong\n}",
        "func foo() {   ↓// Wrong\n}",
        "class Foo {\nvar foo: Date?  ↓// Wrong\n}",
        "class Foo {var foo = Date()↓// Wrong\n}",
        "class Foo {var foo = [1, ↓//Wrong\n2]\n}"
        ]
    )

    private let inlineStartPattern = "(?:\(endOfStatement)\(nonSpaceOrTwoOrMoreSpaces)\(comment))"
    private let inlineEndPattern = "(?:\(endOfStatement)\\s{1}\(comment)\(nonSpaceOrTwoOrMoreSpaces))"

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
                .byteRangeToNSRange(start: syntaxTokens[0].offset + syntaxTokens[0].length, length: 0)

            var commentStart = range
            commentStart.location -= 1
            commentStart.location += range.length - 2 // Sets the "pointer" right before the comment starts

            return identifierRange.map { NSUnionRange($0, commentStart) }
        }
    }
}
