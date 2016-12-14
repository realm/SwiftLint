//
//  OperatorUsageWhitespaceRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/13/16.
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
            "let range = 1 ..<  3\n",
            "let foo = bar   ?? 0\n",
            "let foo = bar??0\n",
            "let foo = bar !=  0\n",
            "let foo = bar !==  bar2\n"
        ]
    )

    public func validateFile(_ file: File) -> [StyleViolation] {
        let escapedOperators = ["/", "=", "-", "+", "*", "|", "^", "~"]
            .map({ "\\\($0)" }).joined()
        let rangePattern = "\\.\\.(?:\\.|<)" // ... or ..<
        let notEqualsPattern = "\\!\\=\\=?" // != or !==
        let coalescingPattern = "\\?{2}"

        let operators = "(?:[\(escapedOperators)%<>&]+|\(rangePattern)|\(coalescingPattern)|" +
            "\(notEqualsPattern))"

        let oneSpace = "[^\\S\\r\\n]" // to allow lines ending with operators to be valid
        let zeroSpaces = oneSpace + "{0}"
        let manySpaces = oneSpace + "{2,}"
        let variableOrNumber = "\\b"

        let spaces = [(zeroSpaces, zeroSpaces), (oneSpace, manySpaces),
                      (manySpaces, oneSpace), (manySpaces, manySpaces)]
        let patterns = spaces.map { first, second in
            variableOrNumber + first + operators + second + variableOrNumber
        }
        let pattern = "(?:\(patterns.joined(separator: "|")))"

        let genericPattern = "<.+?>"
        let validRangePattern = variableOrNumber + zeroSpaces + rangePattern +
            zeroSpaces + variableOrNumber
        let excludingPattern = "(?:\(genericPattern)|\(validRangePattern))"

        let kinds = SyntaxKind.commentAndStringKinds()

        return file.matchPattern(pattern, excludingSyntaxKinds: kinds,
                                 excludingPattern: excludingPattern).map {
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, characterOffset: $0.location))
        }
    }
}
