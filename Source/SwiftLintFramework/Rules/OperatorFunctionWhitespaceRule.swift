//
//  OperatorWhitespaceRule.swift
//  SwiftLint
//
//  Created by Akira Hirakawa on 8/6/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct OperatorFunctionWhitespaceRule: ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "operator_whitespace",
        name: "Operator Function Whitespace",
        description: "Operators should be surrounded by a single whitespace when defining them.",
        nonTriggeringExamples: [
            "func <| (lhs: Int, rhs: Int) -> Int {}\n",
            "func <|< <A>(lhs: A, rhs: A) -> A {}\n",
            "func abc(lhs: Int, rhs: Int) -> Int {}\n"
        ],
        triggeringExamples: [
            "↓func <|(lhs: Int, rhs: Int) -> Int {}\n",   // no spaces after
            "↓func <|<<A>(lhs: A, rhs: A) -> A {}\n",     // no spaces after
            "↓func <|  (lhs: Int, rhs: Int) -> Int {}\n", // 2 spaces after
            "↓func <|<  <A>(lhs: A, rhs: A) -> A {}\n",   // 2 spaces after
            "↓func  <| (lhs: Int, rhs: Int) -> Int {}\n", // 2 spaces before
            "↓func  <|< <A>(lhs: A, rhs: A) -> A {}\n"    // 2 spaces before
        ]
    )

    public func validate(file: File) -> [StyleViolation] {
        let escapedOperators = ["/", "=", "-", "+", "!", "*", "|", "^", "~", "?", "."]
            .map({ "\\\($0)" }).joined()
        let operators = "\(escapedOperators)%<>&"
        let zeroOrManySpaces = "(\\s{0}|\\s{2,})"
        let pattern1 = "func\\s+[\(operators)]+\(zeroOrManySpaces)(<[A-Z]+>)?\\("
        let pattern2 = "func\(zeroOrManySpaces)[\(operators)]+\\s+(<[A-Z]+>)?\\("
        return file.match(pattern: "(\(pattern1)|\(pattern2))").filter { arg -> Bool in
            let (_, syntaxKinds) = arg
            return syntaxKinds.first == .keyword
        }.map { arg in
            let (range, _) = arg
            return StyleViolation(ruleDescription: type(of: self).description,
                severity: configuration.severity,
                location: Location(file: file, characterOffset: range.location))
        }
    }
}
