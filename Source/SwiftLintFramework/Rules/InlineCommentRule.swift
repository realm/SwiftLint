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
private let endOfStatement = "[{}(),:;?]++\(noNewLine)"

public struct InlineCommentRule: ConfigurationProviderRule, OptInRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "inline_comment",
        name: "InlineComment",
        description: "Inline comments should be in valid format. There should only be one space on both sides of '//'",
        kind: .lint,
        nonTriggeringExamples: [
            "// Good\nfunc foo() {\n}",
            "func foo() { // Good\n}",
            "class Foo {var foo = Date() // Good\n}",
            "class Foo {var foo: Date? // Good\n}",
            "class Foo {var foo = [1, // Good\n2]\n}"
        ],
        triggeringExamples: [
            "func foo() { ↓//Wrong 1\n}",
            "func foo() { //   ↓ Wrong 2\n}",
            "func foo() {↓// Wrong 3\n}",
            "func foo() {   ↓// Wrong 4\n}",
            "class Foo {\nvar foo: Date?  ↓// Wrong 5\n}",
            "class Foo {var foo = Date()↓// Wrong 6\n}",
            "class Foo {var foo = [1, ↓//Wrong 7\n2]\n}"
        ]
    )

    private let inlineStartPattern = "(?:\(endOfStatement)\(nonSpaceOrTwoOrMoreSpaces)\(comment))"
    private let inlineEndNonSpacePattern = "(?:\(endOfStatement)\\s{1}\(comment)\(nonSpace))"
    private let inlineEndTwoOrMoreSpacesPattern = "(?:\(endOfStatement)\\s{1}\(comment)\(twoOrMoreSpaces))"

    typealias InlinePattern = (pattern: String, offset: Int)

    private var patterns: [InlinePattern] {
        return [
            (inlineStartPattern, 1),
            (inlineEndNonSpacePattern, 1),
            (inlineEndTwoOrMoreSpacesPattern, 0)
        ]
    }

    public func validate(file: File) -> [StyleViolation] {
        var violationsRange = [NSRange]()

        patterns.forEach({ (arg: (pattern: String, offset: Int)) in
            violationsRange.append(contentsOf: violationRanges(in: file, matching: arg.pattern, offset: arg.offset))
        })

        return violationsRange.map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    private func violationRanges(in file: File, matching pattern: String, offset: Int) -> [NSRange] {
        let nsstring = file.contents.bridge()

        return file.rangesAndTokens(matching: pattern).filter { _, syntaxTokens in
            return !syntaxTokens.isEmpty && SyntaxKind(rawValue: syntaxTokens[0].type) == .comment
        }.flatMap { range, syntaxTokens in
                let identifierRange = nsstring
                    .byteRangeToNSRange(start: syntaxTokens[0].offset + syntaxTokens[0].length, length: 0)

                var commentStart = range
                commentStart.location -= 1
                commentStart.location += range.length - offset // Sets the "pointer" where the comment starts
                return identifierRange.map { NSUnionRange($0, commentStart) }
        }
    }
}
