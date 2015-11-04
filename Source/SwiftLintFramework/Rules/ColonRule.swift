//
//  ColonRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct ColonRule: Rule {
    public init() {}

    public static let description = RuleDescription(
        identifier: "colon",
        name: "Colon",
        description: "This rule checks whether you associate the colon with the identifier.",
        nonTriggeringExamples: [
            "let abc: Void\n",
            "let abc: [Void: Void]\n",
            "let abc: (Void, Void)\n",
            "func abc(def: Void) {}\n"
        ],
        triggeringExamples: [
            "let abc:Void\n",
            "let abc:  Void\n",
            "let abc :Void\n",
            "let abc : Void\n",
            "let abc : [Void: Void]\n",
            "func abc(def:Void) {}\n",
            "func abc(def:  Void) {}\n",
            "func abc(def :Void) {}\n",
            "func abc(def : Void) {}\n"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        let pattern1 = file.matchPattern("\\w+\\s+:\\s*\\S+",
            withSyntaxKinds: [.Identifier, .Typeidentifier])
        let pattern2 = file.matchPattern("\\w+:(?:\\s{0}|\\s{2,})\\S+",
            withSyntaxKinds: [.Identifier, .Typeidentifier])
        return (pattern1 + pattern2).map { range in
            return StyleViolation(ruleDescription: self.dynamicType.description,
                location: Location(file: file, offset: range.location),
                reason: "When specifying a type, always associate the colon with the identifier")
        }
    }
}
