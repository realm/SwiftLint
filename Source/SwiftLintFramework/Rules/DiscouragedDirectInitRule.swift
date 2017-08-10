//
//  DiscourageInitRule.swift
//  SwiftLint
//
//  Created by Ornithologist Coder on 8/1/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct DiscouragedDirectInitRule: ASTRule, ConfigurationProviderRule {
    public var configuration = DiscouragedDirectInitConfiguration()

    public init() {}

    public static let description = RuleDescription(
        identifier: "discouraged_direct_init",
        name: "Discouraged Direct Initialization",
        description: "Discouraged direct initialization of types that can be harmful.",
        kind: .lint,
        nonTriggeringExamples: [
            "let foo = UIDevice.current",
            "let foo = Bundle.main",
            "let foo = Bundle(path: \"bar\")",
            "let foo = Bundle(identifier: \"bar\")",
            "let foo = Bundle.init(path: \"bar\")",
            "let foo = Bundle.init(identifier: \"bar\")"
        ],
        triggeringExamples: [
            "↓UIDevice()",
            "↓Bundle()",
            "let foo = ↓UIDevice()",
            "let foo = ↓Bundle()",
            "let foo = bar(bundle: ↓Bundle(), device: ↓UIDevice())",
            "↓UIDevice.init()",
            "↓Bundle.init()",
            "let foo = ↓UIDevice.init()",
            "let foo = ↓Bundle.init()",
            "let foo = bar(bundle: ↓Bundle.init(), device: ↓UIDevice.init())"
        ]
    )

    public func validate(file: File,
                         kind: SwiftExpressionKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard
            kind == .call,
            let offset = dictionary.nameOffset,
            let name = dictionary.name,
            dictionary.bodyLength == 0,
            configuration.discouragedInits.contains(name)
            else {
                return []
        }

        return [StyleViolation(ruleDescription: type(of: self).description,
                               severity: configuration.severity,
                               location: Location(file: file, byteOffset: offset))]
    }
}
