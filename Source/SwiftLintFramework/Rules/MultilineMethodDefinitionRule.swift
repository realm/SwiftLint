//
//  MultilineMethodDefinitionRule.swift
//  SwiftLint
//
//  Created by Ornithologist Coder on 22/05/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct MultilineMethodDefinitionRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "multiline_method_definition",
        name: "Multiline method definition",
        description: "Methods' parameters should be either on the same line, or one per line.",
        nonTriggeringExamples: [
            "protocol Foo {\n\tfunc foo() { }\n}",
            "protocol Foo {\n\tfunc foo(param1: 1) { }\n}",
            "protocol Foo {\n\tfunc foo(param1: 1, param2: false) { }\n}",
            "protocol Foo {\n\tfunc foo(param1: 1, param2: false, param3: []) { }\n}",
            "protocol Foo {\n" +
            "   func foo(param1: 1,\n" +
            "            param2: false,\n" +
            "            param3: []) { }\n" +
            "}",
            "protocol Foo {\n\tstatic func foo(param1: 1, param2: false, param3: []) { }\n}",
            "protocol Foo {\n" +
            "   static func foo(param1: 1,\n" +
            "                   param2: false,\n" +
            "                   param3: []) { }\n" +
            "}",
            "protocol Foo {\n\tclass func foo(param1: 1, param2: false, param3: []) { }\n}",
            "protocol Foo {\n" +
            "   class func foo(param1: 1,\n" +
            "                  param2: false,\n" +
            "                  param3: []) { }\n" +
            "}",
            "enum Foo {\n\tfunc foo() { }\n}",
            "enum Foo {\n\tfunc foo(param1: 1) { }\n}",
            "enum Foo {\n\tfunc foo(param1: 1, param2: false) { }\n}",
            "enum Foo {\n\tfunc foo(param1: 1, param2: false, param3: []) { }\n}",
            "enum Foo {\n" +
            "   func foo(param1: 1,\n" +
            "            param2: false,\n" +
            "            param3: []) { }\n" +
            "}",
            "enum Foo {\n\tstatic func foo(param1: 1, param2: false, param3: []) { }\n}",
            "enum Foo {\n" +
            "   static func foo(param1: 1,\n" +
            "                   param2: false,\n" +
            "                   param3: []) { }\n" +
            "}",
            "struct Foo {\n\tfunc foo() { }\n}",
            "struct Foo {\n\tfunc foo(param1: 1) { }\n}",
            "struct Foo {\n\tfunc foo(param1: 1, param2: false) { }\n}",
            "struct Foo {\n\tfunc foo(param1: 1, param2: false, param3: []) { }\n}",
            "struct Foo {\n" +
            "   func foo(param1: 1,\n" +
            "            param2: false,\n" +
            "            param3: []) { }\n" +
            "}",
            "struct Foo {\n\tstatic func foo(param1: 1, param2: false, param3: []) { }\n}",
            "struct Foo {\n" +
            "   static func foo(param1: 1,\n" +
            "                   param2: false,\n" +
            "                   param3: []) { }\n" +
            "}",
            "class Foo {\n\tfunc foo() { }\n}",
            "class Foo {\n\tfunc foo(param1: 1) { }\n}",
            "class Foo {\n\tfunc foo(param1: 1, param2: false) { }\n}",
            "class Foo {\n\tfunc foo(param1: 1, param2: false, param3: []) { }\n\t}",
            "class Foo {\n" +
            "   func foo(param1: 1,\n" +
            "            param2: false,\n" +
            "            param3: []) { }\n" +
            "}",
            "class Foo {\n\tclass func foo(param1: 1, param2: false, param3: []) { }\n}",
            "class Foo {\n" +
            "   class func foo(param1: 1,\n" +
            "                  param2: false,\n" +
            "                  param3: []) { }\n" +
            "}"
        ],
        triggeringExamples: [
            "protocol Foo {\n" +
            "   ↓func foo(param1: 1,\n" +
            "             param2: false, param3: []) { }\n" +
            "}",
            "protocol Foo {\n" +
            "   ↓func foo(param1: 1, param2: false,\n" +
            "             param3: []) { }\n" +
            "}",
            "protocol Foo {\n" +
            "   ↓static func foo(param1: 1,\n" +
            "                    param2: false, param3: []) { }\n" +
            "}",
            "protocol Foo {\n" +
            "   ↓static func foo(param1: 1, param2: false,\n" +
            "                    param3: []) { }\n" +
            "}",
            "protocol Foo {\n" +
            "   ↓class func foo(param1: 1,\n" +
            "                   param2: false, param3: []) { }\n" +
            "}",
            "protocol Foo {\n" +
            "   ↓class func foo(param1: 1, param2: false,\n" +
            "                   param3: []) { }\n" +
            "}",
            "enum Foo {\n" +
            "   ↓func foo(param1: 1,\n" +
            "             param2: false, param3: []) { }\n" +
            "}",
            "enum Foo {\n" +
            "   ↓func foo(param1: 1, param2: false,\n" +
            "             param3: []) { }\n" +
            "}",
            "enum Foo {\n" +
            "   ↓static func foo(param1: 1,\n" +
            "                    param2: false, param3: []) { }\n" +
            "}",
            "enum Foo {\n" +
            "   ↓static func foo(param1: 1, param2: false,\n" +
            "                    param3: []) { }\n" +
            "}",
            "struct Foo {\n" +
            "   ↓func foo(param1: 1,\n" +
            "             param2: false, param3: []) { }\n" +
            "}",
            "struct Foo {\n" +
            "   ↓func foo(param1: 1, param2: false,\n" +
            "             param3: []) { }\n" +
            "}",
            "struct Foo {\n" +
            "   ↓static func foo(param1: 1,\n" +
            "                    param2: false, param3: []) { }\n" +
            "}",
            "struct Foo {\n" +
            "   ↓static func foo(param1: 1, param2: false,\n" +
            "                    param3: []) { }\n" +
            "}",
            "class Foo {\n" +
            "   ↓func foo(param1: 1,\n" +
            "             param2: false, param3: []) { }\n" +
            "}",
            "class Foo {\n" +
            "   ↓func foo(param1: 1, param2: false,\n" +
            "             param3: []) { }\n" +
            "}",
            "class Foo {\n" +
            "   ↓class func foo(param1: 1,\n" +
            "                   param2: false, param3: []) { }\n" +
            "}",
            "class Foo {\n" +
            "   ↓class func foo(param1: 1, param2: false,\n" +
            "                   param3: []) { }\n" +
            "}"
        ]
    )

    public func validate(file: File,
                         kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard
            kind == .functionMethodStatic || kind == .functionMethodClass || kind == .functionMethodInstance,
            let offset = dictionary.offset
            else {
                return []
        }

        var numberOfParameters: Int = 0
        var linesWithParameters: Set<Int> = []

        for structure in dictionary.substructure {
            guard
                let offset = structure.offset,
                let (line, _) = file.contents.bridge().lineAndCharacter(forByteOffset: offset),
                structure.kind == SwiftDeclarationKind.varParameter.rawValue
                else {
                    continue
            }

            linesWithParameters.insert(line)
            numberOfParameters += 1
        }

        if linesWithParameters.count > 1 && numberOfParameters != linesWithParameters.count {
            return [StyleViolation(ruleDescription: type(of: self).description,
                                   severity: configuration.severity,
                                   location: Location(file: file, byteOffset: offset))]
        }

        return []
    }
}
