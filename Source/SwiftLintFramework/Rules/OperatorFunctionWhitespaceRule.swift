//
//  OperatorWhitespaceRule.swift
//  SwiftLint
//
//  Created by Akira Hirakawa on 8/6/15.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct OperatorFunctionWhitespaceRule: Rule {
    public init() {}

    public let identifier = "operator_whitespace"

    public func validateFile(file: File) -> [StyleViolation] {
        let operators = ["/", "=", "-", "+", "!", "*", "|", "^", "~", "?", "."].map({"\\\($0)"}) +
            ["%", "<", ">", "&"]
        let zeroOrManySpaces = "(\\s{0}|\\s{2,})"
        let pattern1 = "func\\s+[" +
            operators.joinWithSeparator("") +
            "]+\(zeroOrManySpaces)(<[A-Z]+>)?\\("
        let pattern2 = "func\(zeroOrManySpaces)[" +
            operators.joinWithSeparator("") +
            "]+\\s+(<[A-Z]+>)?\\("
        return file.matchPattern("(\(pattern1)|\(pattern2))").filter { _, syntaxKinds in
            return syntaxKinds.first == .Keyword
        }.map { range, _ in
            return StyleViolation(type: .OperatorFunctionWhitespace,
                location: Location(file: file, offset: range.location),
                severity: .Warning,
                ruleId: self.identifier,
                reason: example.ruleDescription)
        }
    }

    public let example = RuleExample(
        ruleName: "Operator Function Whitespace Rule",
        ruleDescription: "Use a single whitespace around operators when " +
            "defining them.",
        nonTriggeringExamples: [
            "func <| (lhs: Int, rhs: Int) -> Int {}\n",
            "func <|< <A>(lhs: A, rhs: A) -> A {}\n",
            "func abc(lhs: Int, rhs: Int) -> Int {}\n"
        ],
        triggeringExamples: [
            "func <|(lhs: Int, rhs: Int) -> Int {}\n",   // no spaces after
            "func <|<<A>(lhs: A, rhs: A) -> A {}\n",     // no spaces after
            "func <|  (lhs: Int, rhs: Int) -> Int {}\n", // 2 spaces after
            "func <|<  <A>(lhs: A, rhs: A) -> A {}\n",   // 2 spaces after
            "func  <| (lhs: Int, rhs: Int) -> Int {}\n", // 2 spaces before
            "func  <|< <A>(lhs: A, rhs: A) -> A {}\n"    // 2 spaces before
        ]
    )
}
