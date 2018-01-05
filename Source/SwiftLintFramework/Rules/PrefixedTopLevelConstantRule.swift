//
//  PrefixedConstantRule.swift
//  SwiftLint
//
//  Created by Ornithologist Coder on 1/5/18.
//  Copyright © 2018 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct PrefixedTopLevelConstantRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "prefixed_toplevel_constant",
        name: "Prefixed Top-Level Constant",
        description: "Top-level constants should be prefixed by `k`.",
        kind: .style,
        nonTriggeringExamples: [
            "private let kFoo = 20.0",
            "public let kFoo = false",
            "internal let kFoo = \"Foo\"",
            "let kFoo = true",
            "struct Foo {\n" +
            "   let bar = 20.0\n" +
            "}",
            "private var foo = 20.0",
            "public var foo = false",
            "internal var foo = \"Foo\"",
            "var foo = true"
        ],
        triggeringExamples: [
            "private let ↓Foo = 20.0",
            "public let ↓Foo = false",
            "internal let ↓Foo = \"Foo\"",
            "let ↓Foo = true",
            "let ↓foo = 2, ↓bar = true"
        ]
    )

    public func validate(file: File,
                         kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard
            kind == .varGlobal,
            let offset = dictionary.offset,
            let nameOffset = dictionary.nameOffset,
            let name = dictionary.name,
            let content = file.contents.bridge().substringWithByteRange(start: offset, length: nameOffset - offset),
            content.hasPrefix("let") && !name.hasPrefix("k")
            else {
                return []
        }

        return [StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: nameOffset))]
    }
}
