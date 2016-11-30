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
    public var configuration = SeverityConfiguration(.Warning)

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
            "let x: CustomArray<String>"
        ],
        triggeringExamples: [
            "let x: ↓Array<String>",
            "let x: ↓Dictionary<Int, String>",
            "let x: ↓Optional<Int>",
            "let x: ↓ImplicitlyUnwrappedOptional<Int>",
            "func x(a: ↓Array<Int>, b: Int) -> [Int: Any]",
            "func x(a: [Int], b: Int) -> ↓Dictionary<Int, String>",
            "func x(a: ↓Array<Int>, b: Int) -> ↓Dictionary<Int, String>"
        ]
    )

    public func validateFile(_ file: File) -> [StyleViolation] {
        let types = ["Optional", "ImplicitlyUnwrappedOptional", "Array", "Dictionary"]

        let pattern = "\\b(" + types.joined(separator: "|") + ")\\s*<.*?>"

        return file.matchPattern(pattern,
            excludingSyntaxKinds: SyntaxKind.commentAndStringKinds()).map {
                StyleViolation(ruleDescription: type(of: self).description,
                    severity: configuration.severity,
                    location: Location(file: file, characterOffset: $0.location))
        }
    }

}
