//
//  ColonRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct ColonRule: Rule, RuleExample {
    let identifier = "colon"
    let parameters = [RuleParameter<Void>]()

    func validateFile(file: File) -> [StyleViolation] {
        let pattern1 = file.matchPattern("\\w+\\s+:\\s*\\S+",
            withSyntaxKinds: [.Identifier, .Typeidentifier])
        let pattern2 = file.matchPattern("\\w+:(?:\\s{0}|\\s{2,})\\S+",
            withSyntaxKinds: [.Identifier, .Typeidentifier])
        return (pattern1 + pattern2).map { range in
            return StyleViolation(type: .Colon,
                location: Location(file: file, offset: range.location),
                severity: .Low,
                reason: "When specifying a type, always associate the colon with the identifier")
        }
    }

    public var ruleName = "Colon Rule"

    public var ruleDescription = "This rule checks whether you associate the colon with the identifier."

    public var correctExamples = [
        "let abc: Void\n",
        "let abc: [Void: Void]\n",
        "let abc: (Void, Void)\n",
        "func abc(def: Void) {}\n"
    ]

    public var failingExamples = [
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

}
