//
//  MultilineMethodDefinitionRule.swift
//  SwiftLint
//
//  Created by Ornithologist Coder on 22/05/17.
//  Copyright © 2017 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct MultilineParametersDefinitionRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "multiline_parameters_definition",
        name: "Multiline parameters definition",
        description: "Functions and methods parameters should be either on the same line, or one per line.",
        nonTriggeringExamples: [
            "func foo() { }",
            "func foo(param1: Int) { }",
            "func foo(param1: Int, param2: Bool) { }",
            "func foo(param1: Int, param2: Bool, param3: [String]) { }",
            "func foo(param1: Int,\n" +
            "         param2: Bool,\n" +
            "         param3: [String]) { }",
            "func foo(_ param1: Int, param2: Int, param3: Int) -> (Int) -> Int {\n" +
            "   return { x in x + param1 + param2 + param3 }\n" +
            "}",
            "static func foo() { }",
            "static func foo(param1: Int) { }",
            "static func foo(param1: Int, param2: Bool) { }",
            "static func foo(param1: Int, param2: Bool, param3: [String]) { }",
            "static func foo(param1: Int,\n" +
            "                param2: Bool,\n" +
            "                param3: [String]) { }",
            "protocol Foo {\n\tfunc foo() { }\n}",
            "protocol Foo {\n\tfunc foo(param1: Int) { }\n}",
            "protocol Foo {\n\tfunc foo(param1: Int, param2: Bool) { }\n}",
            "protocol Foo {\n\tfunc foo(param1: Int, param2: Bool, param3: [String]) { }\n}",
            "protocol Foo {\n" +
            "   func foo(param1: Int,\n" +
            "            param2: Bool,\n" +
            "            param3: [String]) { }\n" +
            "}",
            "protocol Foo {\n\tstatic func foo(param1: Int, param2: Bool, param3: [String]) { }\n}",
            "protocol Foo {\n" +
            "   static func foo(param1: Int,\n" +
            "                   param2: Bool,\n" +
            "                   param3: [String]) { }\n" +
            "}",
            "protocol Foo {\n\tclass func foo(param1: Int, param2: Bool, param3: [String]) { }\n}",
            "protocol Foo {\n" +
            "   class func foo(param1: Int,\n" +
            "                  param2: Bool,\n" +
            "                  param3: [String]) { }\n" +
            "}",
            "enum Foo {\n\tfunc foo() { }\n}",
            "enum Foo {\n\tfunc foo(param1: Int) { }\n}",
            "enum Foo {\n\tfunc foo(param1: Int, param2: Bool) { }\n}",
            "enum Foo {\n\tfunc foo(param1: Int, param2: Bool, param3: [String]) { }\n}",
            "enum Foo {\n" +
            "   func foo(param1: Int,\n" +
            "            param2: Bool,\n" +
            "            param3: [String]) { }\n" +
            "}",
            "enum Foo {\n\tstatic func foo(param1: Int, param2: Bool, param3: [String]) { }\n}",
            "enum Foo {\n" +
            "   static func foo(param1: Int,\n" +
            "                   param2: Bool,\n" +
            "                   param3: [String]) { }\n" +
            "}",
            "struct Foo {\n\tfunc foo() { }\n}",
            "struct Foo {\n\tfunc foo(param1: Int) { }\n}",
            "struct Foo {\n\tfunc foo(param1: Int, param2: Bool) { }\n}",
            "struct Foo {\n\tfunc foo(param1: Int, param2: Bool, param3: [String]) { }\n}",
            "struct Foo {\n" +
            "   func foo(param1: Int,\n" +
            "            param2: Bool,\n" +
            "            param3: [String]) { }\n" +
            "}",
            "struct Foo {\n\tstatic func foo(param1: Int, param2: Bool, param3: [String]) { }\n}",
            "struct Foo {\n" +
            "   static func foo(param1: Int,\n" +
            "                   param2: Bool,\n" +
            "                   param3: [String]) { }\n" +
            "}",
            "class Foo {\n\tfunc foo() { }\n}",
            "class Foo {\n\tfunc foo(param1: Int) { }\n}",
            "class Foo {\n\tfunc foo(param1: Int, param2: Bool) { }\n}",
            "class Foo {\n\tfunc foo(param1: Int, param2: Bool, param3: [String]) { }\n\t}",
            "class Foo {\n" +
            "   func foo(param1: Int,\n" +
            "            param2: Bool,\n" +
            "            param3: [String]) { }\n" +
            "}",
            "class Foo {\n\tclass func foo(param1: Int, param2: Bool, param3: [String]) { }\n}",
            "class Foo {\n" +
            "   class func foo(param1: Int,\n" +
            "                  param2: Bool,\n" +
            "                  param3: [String]) { }\n" +
            "}"
        ],
        triggeringExamples: [
            "func ↓foo(_ param1: Int,\n" +
            "          param2: Int, param3: Int) -> (Int) -> Int {\n" +
            "   return { x in x + param1 + param2 + param3 }\n" +
            "}",
            "protocol Foo {\n" +
            "   func ↓foo(param1: Int,\n" +
            "             param2: Bool, param3: [String]) { }\n" +
            "}",
            "protocol Foo {\n" +
            "   func ↓foo(param1: Int, param2: Bool,\n" +
            "             param3: [String]) { }\n" +
            "}",
            "protocol Foo {\n" +
            "   static func ↓foo(param1: Int,\n" +
            "                    param2: Bool, param3: [String]) { }\n" +
            "}",
            "protocol Foo {\n" +
            "   static func ↓foo(param1: Int, param2: Bool,\n" +
            "                    param3: [String]) { }\n" +
            "}",
            "protocol Foo {\n" +
            "   class func ↓foo(param1: Int,\n" +
            "                   param2: Bool, param3: [String]) { }\n" +
            "}",
            "protocol Foo {\n" +
            "   class func ↓foo(param1: Int, param2: Bool,\n" +
            "                   param3: [String]) { }\n" +
            "}",
            "enum Foo {\n" +
            "   func ↓foo(param1: Int,\n" +
            "             param2: Bool, param3: [String]) { }\n" +
            "}",
            "enum Foo {\n" +
            "   func ↓foo(param1: Int, param2: Bool,\n" +
            "             param3: [String]) { }\n" +
            "}",
            "enum Foo {\n" +
            "   static func ↓foo(param1: Int,\n" +
            "                    param2: Bool, param3: [String]) { }\n" +
            "}",
            "enum Foo {\n" +
            "   static func ↓foo(param1: Int, param2: Bool,\n" +
            "                    param3: [String]) { }\n" +
            "}",
            "struct Foo {\n" +
            "   func ↓foo(param1: Int,\n" +
            "             param2: Bool, param3: [String]) { }\n" +
            "}",
            "struct Foo {\n" +
            "   func ↓foo(param1: Int, param2: Bool,\n" +
            "             param3: [String]) { }\n" +
            "}",
            "struct Foo {\n" +
            "   static func ↓foo(param1: Int,\n" +
            "                    param2: Bool, param3: [String]) { }\n" +
            "}",
            "struct Foo {\n" +
            "   static func ↓foo(param1: Int, param2: Bool,\n" +
            "                    param3: [String]) { }\n" +
            "}",
            "class Foo {\n" +
            "   func ↓foo(param1: Int,\n" +
            "             param2: Bool, param3: [String]) { }\n" +
            "}",
            "class Foo {\n" +
            "   func ↓foo(param1: Int, param2: Bool,\n" +
            "             param3: [String]) { }\n" +
            "}",
            "class Foo {\n" +
            "   class func ↓foo(param1: Int,\n" +
            "                   param2: Bool, param3: [String]) { }\n" +
            "}",
            "class Foo {\n" +
            "   class func ↓foo(param1: Int, param2: Bool,\n" +
            "                   param3: [String]) { }\n" +
            "}"
        ]
    )

    public func validate(file: File,
                         kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        guard isValidFunction(kind),
            let offset = dictionary.nameOffset,
            let length = dictionary.nameLength
            else {
                return []
        }

        var numberOfParameters: Int = 0
        var linesWithParameters: Set<Int> = []

        for structure in dictionary.substructure {
            guard
                let structureOffset = structure.offset,
                let (line, _) = file.contents.bridge().lineAndCharacter(forByteOffset: structureOffset),
                structure.kind == SwiftDeclarationKind.varParameter.rawValue,
                structure.typeName != nil
                else {
                    continue
            }

            guard offset..<(offset + length) ~= structureOffset else { break }

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

    // MARK: - Private

    private func isValidFunction(_ kind: SwiftDeclarationKind) -> Bool {
        return [
            SwiftDeclarationKind.functionMethodStatic,
            SwiftDeclarationKind.functionMethodClass,
            SwiftDeclarationKind.functionMethodInstance,
            SwiftDeclarationKind.functionFree
        ].contains(kind)
    }
}
