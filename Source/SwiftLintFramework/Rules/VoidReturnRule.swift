//
//  VoidReturnRule.swift
//  SwiftLint
//
//  Created by Marcelo Fabri on 12/12/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct VoidReturnRule: Rule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "void_return",
        name: "Void Return",
        description: "Prefer `-> Void` over `-> ()`.",
        nonTriggeringExamples: [
            "let abc: () -> Void = {}\n",
            "func foo(completion: () -> Void)\n"
        ],
        triggeringExamples: [
            "let abc: () -> ↓() = {}\n",
            "func foo(completion: () -> ↓())\n",
            "func foo(completion: () -> ↓(   ))\n"
        ]
    )

    public func validateFile(_ file: File) -> [StyleViolation] {
        let kinds = SyntaxKind.commentAndStringKinds()

        return file.matchPattern("->\\s*\\(\\s*\\)", excludingSyntaxKinds: kinds).flatMap {

            let range = file.contents.bridge().substring(with: $0).bridge().range(of: "(")
            guard range.location != NSNotFound else {
                return nil
            }

            let offset = range.location + $0.location
            return StyleViolation(ruleDescription: type(of: self).description,
                                  severity: configuration.severity,
                                  location: Location(file: file, characterOffset: offset))
        }
    }
}
