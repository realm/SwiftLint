//
//  ConditionalBindingCascadeRule.swift
//  SwiftLint
//
//  Created by Aaron McTavish on 08/01/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

import SourceKittenFramework

public struct ConditionalBindingCascadeRule: Rule {
    public static let description = RuleDescription(
        identifier: "conditional_binding_cascade",
        name: "Conditional Binding Cascade",
        description: "Repeated `let` statements in conditional binding cascade should be avoided.",
        nonTriggeringExamples: [
            "if let a = b, c = d {",
            "if let a = b, \n c = d {",
            "if let a = b, \n c = d \n {",
            "guard let a = b, c = d else {"
        ],
        triggeringExamples: [
            "if let a = b, let c = d {",
            "if let a = b, \n let c = d {",
            "if let a = b, c = d, let e = f {",
            "if let a = b, let c = d \n {",
            "if \n let a = b, let c = d {",
            "if let a = b, c = d.indexOf({$0 == e}), let f = g {",
            "guard let a = b, let c = d else {"
        ]
    )

    public func validateFile(file: File) -> [StyleViolation] {
        let conditionalBindingKeywords = ["if", "guard"]
        let pattern =  "^(" +
                        conditionalBindingKeywords.joinWithSeparator("|") +
                        ")(\\s*?)let((.|\\s)*?)let((.|\\s)*?)\\{"
        return file.matchPattern(pattern,
            excludingSyntaxKinds: SyntaxKind.commentAndStringKinds()).map {
                StyleViolation(ruleDescription: self.dynamicType.description,
                    location: Location(file: file, characterOffset: $0.location))
        }
    }
}
