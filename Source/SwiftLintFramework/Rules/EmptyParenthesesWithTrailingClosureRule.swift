//
//  EmptyParenthesesWithTrailingClosureRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 11/12/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct EmptyParenthesesWithTrailingClosureRule: ASTRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "empty_parentheses_with_trailing_closure",
        name: "Empty Parentheses with Trailing Closure",
        description: "When using trailing closures, empty parentheses should be avoided " +
                     "after the method call.",
        nonTriggeringExamples: [
            "[1, 2].map { $0 + 1 }\n",
            "[1, 2].map({ $0 + 1 })\n",
            "[1, 2].reduce(0) { $0 + $1 }",
            "[1, 2].map { number in\n number + 1 \n}\n",
            "let isEmpty = [1, 2].map.isEmpty()\n"
        ],
        triggeringExamples: [
            "[1, 2].map↓() { $0 + 1 }",
            "[1, 2].map↓( ) { $0 + 1 }\n",
            "[1, 2].map↓() { number in\n number + 1 \n}\n",
            "[1, 2].map↓(  ) { number in\n number + 1 \n}\n"
        ]
    )

    public enum Kind: String {
        case exprCall = "source.lang.swift.expr.call"
        case other
        public init?(rawValue: String) {
            switch rawValue {
            case Kind.exprCall.rawValue:
                self = .exprCall
            default:
                self = .other
            }
        }
    }

    private static let emptyParenthesesRegex = regex("^\\s*\\(\\s*\\)")

    public func validateFile(_ file: File,
                             kind: Kind,
                             dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard kind == .exprCall else {
            return []
        }

        guard let offset = (dictionary["key.offset"] as? Int64).flatMap({ Int($0) }),
            let length = (dictionary["key.length"] as? Int64).flatMap({ Int($0) }),
            let nameOffset = (dictionary["key.nameoffset"] as? Int64).flatMap({ Int($0) }),
            let nameLength = (dictionary["key.namelength"] as? Int64).flatMap({ Int($0) }),
            let bodyLength = (dictionary["key.bodylength"] as? Int64).flatMap({ Int($0) }),
            bodyLength > 0 else {
                return []
        }

        let rangeStart = nameOffset + nameLength
        let rangeLength = (offset + length) - (nameOffset + nameLength)
        let regex = EmptyParenthesesWithTrailingClosureRule.emptyParenthesesRegex

        guard let range = file.contents.bridge()
                              .byteRangeToNSRange(start: rangeStart, length: rangeLength),
            let match = regex.firstMatch(in: file.contents, options: [], range: range),
            match.range.location != NSNotFound else {
                return []
        }

        return [
            StyleViolation(ruleDescription: type(of: self).description,
                           severity: configuration.severity,
                           location: Location(file: file, byteOffset: rangeStart))
        ]
    }
}
