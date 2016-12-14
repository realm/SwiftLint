//
//  OperatorUsageWhitespaceRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 13/12/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct OperatorUsageWhitespaceRule: OptInRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "operator_usage_whitespace",
        name: "Operator Usage Whitespace",
        description: "Operators should be surrounded by a single whitespace " +
                     "when they are being used.",
        nonTriggeringExamples: [
            "let foo = 1 + 2\n",
            "let foo = 1 > 2\n",
            "let foo = !false\n",
            "let foo: Int?\n",
            "let foo: Array<String>\n",
            "let foo: [String]\n",
            "let foo = 1 + \n  2\n",
            "let range = 1...3\n",
            "let range = 1 ... 3\n",
            "let range = 1..<3\n"
        ],
        triggeringExamples: [
            "let foo = 1+2\n",
            "let foo = 1   + 2\n",
            "let foo = 1   +    2\n",
            "let foo = 1 +    2\n",
            "let foo=1+2\n",
            "let foo=1 + 2\n",
            "let foo=bar\n",
            "let range = 1 ..<  3\n"
        ]
    )

    public func validateFile(_ file: File) -> [StyleViolation] {
        let escapedOperators = ["/", "=", "-", "+", "*", "|", "^", "~"]
            .map({ "\\\($0)" }).joined()
        let rangePattern = "\\.\\.(?:\\.|<)" // ... or ..<
        let operators = "(?:[\(escapedOperators)%<>&]+|\(rangePattern))"

        let oneSpace = "[^\\S\\r\\n]" // to allow lines ending with operators to be valid
        let zeroSpaces = oneSpace + "{0}"
        let manySpaces = oneSpace + "{2,}"
        let variableOrNumber = "(?:\(RegexHelpers.varName)|\(RegexHelpers.number))"

        let pattern1 = variableOrNumber + zeroSpaces + operators + zeroSpaces + variableOrNumber
        let pattern2 = variableOrNumber + oneSpace + operators + manySpaces + variableOrNumber
        let pattern3 = variableOrNumber + manySpaces + operators + oneSpace + variableOrNumber
        let pattern4 = variableOrNumber + manySpaces + operators + manySpaces + variableOrNumber

        let genericPattern = "<.+?>"
        let validRangePattern = variableOrNumber + zeroSpaces + rangePattern +
            zeroSpaces + variableOrNumber

        let pattern = [pattern1, pattern2, pattern3, pattern4].joined(separator: "|")
        let excludingPattern = "(?:\(genericPattern)|\(validRangePattern))"
        let kinds = SyntaxKind.commentAndStringKinds()

        return file.matchPattern("(?:\(pattern))", excludingSyntaxKinds: kinds,
                                 excludingPattern: excludingPattern).map {
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, characterOffset: $0.location))
        }
    }
}
