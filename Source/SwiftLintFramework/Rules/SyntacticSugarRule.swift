//
//  SyntacticSugarRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 21/10/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import SourceKittenFramework
import Foundation

public struct SyntacticSugarRule: Rule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "syntactic_sugar",
        name: "Syntactic Sugar",
        description: "Shorthand syntactic sugar should be used, i.e. [Int] instead of Array<Int>",
        nonTriggeringExamples: [
            "let x: [Int]",
            "let x: [Int: String]",
            "let x: Int?",
            "func x(a: [Int], b: Int) -> [Int: Any]",
            "let x: Int!",
            "extension Array { \n func x() { } \n }",
            "extension Dictionary { \n func x() { } \n }",
            "let x: CustomArray<String>",
            "var currentIndex: Array<OnboardingPage>.Index?",
            "func x(a: [Int], b: Int) -> Array<Int>.Index",
            "unsafeBitCast(nonOptionalT, to: Optional<T>.self)"
        ],
        triggeringExamples: [
            "let x: ↓Array<String>",
            "let x: ↓Dictionary<Int, String>",
            "let x: ↓Optional<Int>",
            "let x: ↓ImplicitlyUnwrappedOptional<Int>",
            "func x(a: ↓Array<Int>, b: Int) -> [Int: Any]",
            "func x(a: [Int], b: Int) -> ↓Dictionary<Int, String>",
            "func x(a: ↓Array<Int>, b: Int) -> ↓Dictionary<Int, String>",
            "let x = ↓Array<String>.array(of: object)"
        ]
    )

    public func validateFile(_ file: File) -> [StyleViolation] {
        let types = ["Optional", "ImplicitlyUnwrappedOptional", "Array", "Dictionary"]
        let pattern = "\\b(" + types.joined(separator: "|") + ")\\s*<.*?>"
        let kinds = SyntaxKind.commentAndStringKinds()
        let contents = file.contents.bridge()

        return file.matchPattern(pattern, excludingSyntaxKinds: kinds).flatMap { range in

            // avoid triggering when referring to an associatedtype
            let start = range.location + range.length
            let restOfFileRange = NSRange(location: start, length: contents.length - start)
            if regex("\\s*\\.").firstMatch(in: file.contents, options: [],
                                           range: restOfFileRange)?.range.location == start {
                guard let byteOffset = contents.NSRangeToByteRange(start: range.location,
                                                                   length: range.length)?.location else {
                    return nil
                }

                let kinds = file.structure.kindsFor(byteOffset).flatMap { SwiftExpressionKind(rawValue: $0.kind) }
                guard kinds.contains(.call) else {
                    return nil
                }

                if file.matchPattern("\\s*\\.self", withSyntaxKinds: [.keyword],
                                     range: restOfFileRange).first?.location == start {
                    return nil
                }
            }

            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, characterOffset: range.location))
        }
    }

}
