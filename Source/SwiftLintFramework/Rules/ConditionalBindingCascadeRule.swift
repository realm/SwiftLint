//
//  ConditionalBindingCascadeRule.swift
//  SwiftLint
//
//  Created by Aaron McTavish on 08/01/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ConditionalBindingCascadeRule: ConfigurationProviderRule {

    public var configuration = SeverityConfig(.Warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "conditional_binding_cascade",
        name: "Conditional Binding Cascade",
        description: "Repeated `let` statements in conditional binding cascade should be avoided.",
        nonTriggeringExamples: [
            "if let a = b, c = d {",
            "if let a = b, \n c = d {",
            "if let a = b, \n c = d \n {",
            "if let a = b { if let c = d {",
            "if let a = b { let c = d({ foo in ... })",
            "guard let a = b, c = d else {",
            "guard let a = b where a, let c = d else {"
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
        return file.matchPattern("^(if|guard)(.*?)let(.*?),(.*?)let(.*?)\\{",
            excludingSyntaxKinds: SyntaxKind.commentAndStringKinds()).filter {
                !(file.contents as NSString).substringWithRange($0).containsString("where")
            }.map {
                StyleViolation(ruleDescription: self.dynamicType.description,
                               severity: configuration.severity,
                               location: Location(file: file, characterOffset: $0.location))
        }
    }
}
