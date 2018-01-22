//
//  CommentSpaceRule.swift
//  SwiftLint
//
//  Created by Coder-256 on 1/22/18.
//  Copyright © 2018 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct CommentSpaceRule: CorrectableRule, ConfigurationProviderRule, OptInRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "comment_space",
        name: "Comment Space",
        description: "There should be a space around the contents of comments.",
        kind: .style,
        nonTriggeringExamples: [
            "func abc() // foo",
            "// I am a comment.\nfunc abc()",
            "/// This function is interesting.\nfunc abc()",
            "/* I am a\nmultiline comment. */",
            "/*\nI am also a\nmultiline comment.\n*/",
            "/**\n Does something.\n - parameter bar: A number.\n*/\nfunc foo(bar: Int) {}"
        ],
        triggeringExamples: [
            "func abc() //↓foo",
            "//↓I am a comment.\nfunc abc()",
            "///↓This function is interesting.\nfunc abc()",
            "/*↓I am a\nmultiline comment.↓*/",
            "/*\nI am also a\nmultiline comment.↓*/",
            "/**↓Does something.\n - parameter bar: A number.\n*/\nfunc foo(bar: Int) {}"
        ],
        corrections: [
            "func abc() //↓foo": "func abc() // foo",
            "//↓I am a comment.\nfunc abc()": "// I am a comment.\nfunc abc()",
            "///↓This function is interesting.\nfunc abc()": "/// This function is interesting.\nfunc abc()",
            "/*↓I am a\nmultiline comment.*/": "/* I am a\nmultiline comment. */",
            "/*\nI am also a\nmultiline comment.↓*/": "/*\nI am also a\nmultiline comment. */",
            "/**↓Does something.\n - parameter bar: A number.\n*/\nfunc foo(bar: Int) {}":
            "/** Does something.\n - parameter bar: A number.\n*/\nfunc foo(bar: Int) {}"
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        return violationRanges(in: file).map {
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, characterOffset: $0.location))
        }
    }

    public func correct(file: File) -> [Correction] {
        let violations = violationRanges(in: file)
        let matches = file.ruleEnabled(violatingRanges: violations, for: self)
        if matches.isEmpty { return [] }

        let contents = NSMutableString(string: file.contents)
        let description = type(of: self).description
        var corrections = [Correction]()
        for range in matches.reversed() {
            contents.insert(" ", at: range.location)
            let location = Location(file: file, characterOffset: range.location)
            corrections.append(Correction(ruleDescription: description, location: location))
        }
        file.write(contents.bridge())
        return corrections
    }

    private static let pattern = "(?:" + "\\/\\/[^\\w\\s]?+(\\S)" + // Single-line
        "|" + "\\/\\*[^\\w\\s]?+(\\S)?.*?(?:\\S(\\*)|\\*)\\/" + // Multi-line
    ")"

    private static let regularExpression = regex(pattern, options: [])

    private func rangesFromMatches(_ matches: [NSTextCheckingResult]) -> [NSRange] {
        return matches.flatMap { match in
            (1...match.numberOfRanges).map { match.range(at: $0) }
        }
    }

    private func violationRanges(in file: File) -> [NSRange] {
        let contents = file.contents
        let range = NSRange(location: 0, length: contents.bridge().length)
        let syntaxMap = file.syntaxMap
        return rangesFromMatches(CommentSpaceRule.regularExpression.matches(in: contents, options: [], range: range))
            .filter { syntaxMap.kinds(inByteRange: $0).contains(where: SyntaxKind.commentKinds.contains) }
    }
}
