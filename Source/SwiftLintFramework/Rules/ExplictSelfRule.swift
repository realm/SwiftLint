//
//  ExplictSelfRule.swift
//  SwiftLint
//
//  Created by Ian Keen on 2016-10-06.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

func nonTriggering(type: String) -> [String] {
    return [
        "\(type) Good1 { let value: Int = 42; var property: Int { return self.value } }",
        "\(type) Good2 { let value: Int = 42; func function() -> Int { return self.value } }",
        "\(type) Good3 { let value: Int; init() { self.value = 42 } }",
        "\(type) Good4 { func value() -> Int { return 42 }; "
            + "func function() -> Int { return self.value() } }",
        "\(type) Good4a { func value() -> Int { return 42 }; "
            + "func function() -> Int { return self.value() } }",
        "\(type) Good4b { func value(foo: Int) -> Int { return foo }; "
            + "func function() -> Int { return self.value(42) } }",
        "\(type) Good4c { func value(foo: Int, bar: Int) -> Int { return foo + bar }; "
            + "func function() -> Int { return self.value(40, bar: 2) } }",
        "\(type) Good4d { func value(foo bar: Int, baz: Int) -> Int { return bar + baz }; "
            + "func function() -> Int { return self.value(foo: 40, baz: 2) } }",
        "\(type) Good5 { func value() -> Int { return 42 }; "
            + "var property: Int { return self.value() } }",
        "\(type) Good6 { func value() { }; init() { self.value() } }",
        "\(type) Good7 { let value: Int = 42 }; "
            + "extension Good7 { var property: Int { return self.value } }",
        "\(type) Good8 { func value() -> Int { return 42 } }; "
            + "extension Good8 { var property: Int { return self.value() } }",
        "\(type) Good9 { let value: Int = 42 }; "
            + "extension Good9 { func function() -> Int { return self.value } }",
        "\(type) Good10 { func value(foo: String) -> Int { return 42 } }; "
            + "extension Good10 { func function() -> Int { return self.value() } }",
        "\(type) Good11 { static var value: Int = 42; "
            + "static var property: Int { return self.value } }",
        "\(type) Good12 { static func value() -> Int { return 42; }; "
            + "static var property: Int { return self.value() } }",
        "\(type) Good13 { static var value: Int = 42; "
            + "static func function() -> Int { return self.value } }",
        "\(type) Good14 { static func value() -> Int { return 42; }; "
            + "static func function() -> Int { return self.value() } }",
        "\(type) Edge1 { let value: Int = 42; "
            + "func function(value: Int) -> Int { return value } }",
        "\(type) Edge2 { func value() -> Int { return 42 }; "
            + "func function(value: Int) -> Int { return value } }",
    ]
}
let nonTriggeringClassExamples = [
    "class Good15_A { var value: Int = 42 }; "
        + "class Good15_B: Good15_A { var property: Int { return self.value } }",
    "class Good16_A { func value() -> Int { return 42 } }; "
        + "class Good16_B: Good16_A { var property: Int { return self.value() } }",
    "class Good17_A { var value: Int = 42 }; "
        + "class Good17_B: Good17_A { func function() -> Int { return self.value } }",
    "class Good18_A { func value() -> Int { return 42 } }; "
        + "class Good18_B: Good18_A { func function() -> Int { return self.value() } }",
]

func triggering(type: String) -> [String] {
    return [
        "\(type) Bad1 { let value: Int = 42; var property: Int { return value } }",
        "\(type) Bad2 { let value: Int = 42; func function() -> Int { return value } }",
        "\(type) Bad3 { let value: Int; init() { value = 42 } }",
        "\(type) Bad4 { func value() -> Int { return 42 }; "
            + "func function() -> Int { return value() } }",
        "\(type) Bad4a { func value() -> Int { return 42 }; "
            + "func function() -> Int { return value() } }",
        "\(type) Bad4b { func value(foo: Int) -> Int { return foo }; "
            + "func function() -> Int { return value(42) } }",
        "\(type) Bad4c { func value(foo: Int, bar: Int) -> Int { return foo + bar }; "
            + "func function() -> Int { return value(40, bar: 2) } }",
        "\(type) Bad4d { func value(foo bar: Int, baz: Int) -> Int { return bar + baz }; "
            + "func function() -> Int { return value(foo: 40, baz: 2) } }",
        "\(type) Bad5 { func value() -> Int { return 42 }; var property: Int { return value() } }",
        "\(type) Bad6 { func value() { }; init() { value() } }",
        "\(type) Bad7 { let value: Int = 42 }; "
            + "extension Bad7 { var property: Int { return value } }",
        "\(type) Bad8 { func value() -> Int { return 42 } }; "
            + "extension Bad8 { var property: Int { return value() } }",
        "\(type) Bad9 { let value: Int = 42 }; "
            + "extension Bad9 { func function() -> Int { return value } }",
        "\(type) Bad10 { func value() -> Int { return 42 } }; "
            + "extension Bad10 { func function() -> Int { return value() } }",
        "\(type) Bad11 { static var value: Int = 42; static var property: Int { return value } }",
        "\(type) Bad12 { static func value() -> Int { return 42; }; "
            + "static var property: Int { return value() } }",
        "\(type) Bad13 { static var value: Int = 42; "
            + "static func function() -> Int { return value } }",
        "\(type) Bad14 { static func value() -> Int { return 42; }; "
            + "static func function() -> Int { return value() } }"
    ]
}
let triggeringClassExamples = [
    "class Bad15_A { var value: Int = 42 }; "
        + "class Bad15_B: Bad15_A { var property: Int { return value } }",
    "class Bad16_A { func value() -> Int { return 42 } }; "
        + "class Bad16_B: Bad16_A { var property: Int { return value() } }",
    "class Bad17_A { var value: Int = 42 }; "
        + "class Bad17_B: Bad17_A { func function() -> Int { return value } }",
    "class Bad18_A { func value() -> Int { return 42 } }; "
        + "class Bad18_B: Bad18_A { func function() -> Int { return value() } }",
]

let nonTriggeringExamples = ["class", "struct"].flatMap(nonTriggering)
let triggeringExamples = ["class", "struct"].flatMap(triggering)

public struct ExplicitSelfRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.Error)

    public init() { }

    public static let description = RuleDescription(
        identifier: "explicitSelf",
        name: "Explict Self",
        description: "Require explicit self for instance members",
        nonTriggeringExamples: nonTriggeringExamples + nonTriggeringClassExamples,
        triggeringExamples: triggeringExamples + triggeringClassExamples
    )

    public func validateFile(
        file: File,
        kind: SwiftDeclarationKind,
        dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {

        //only check kinds that might require `self.`
        let types: [SwiftDeclarationKind] = [
            .FunctionMethodInstance, .VarInstance,
            .FunctionMethodStatic, .VarStatic,
        ]
        guard types.contains(kind) else { return [] }

        //build a set of instance/static memebers
        let memberTypes: [SwiftDeclarationKind] = [
            .FunctionMethodInstance, .VarInstance,
            .FunctionMethodStatic, .VarStatic,
        ]
        let instanceMembers = file.members(memberTypes)
        let instanceMemberNames = instanceMembers.flatMap { $0["key.name"] as? String }

        //get the members body (functions and calculated properties will have this data)
        guard
            let bodyLocation = (dictionary["key.bodyoffset"] as? Int64).flatMap({ Int($0) }),
            let bodyLength = (dictionary["key.bodylength"] as? Int64).flatMap({ Int($0) })
            else { return [] }

        //get all the tokens inside the body
        let range = NSRange(location: bodyLocation, length: bodyLength)
        let tokens = file.syntaxMap.tokensIn(range)

        //get parameters (if any)
        let parameters = file
            .members(dictionary, declarations: [SwiftDeclarationKind.VarParameter])
            .flatMap { $0["key.name"] as? String }

        var violations: [StyleViolation] = []

        var previous: [String] = []
        for token in tokens {
            guard let type = SyntaxKind(rawValue: token.type) else { continue }

            let value = token.name(file)
            defer { previous.append(value) }

            let allowedSuffixes: [[String]] = [
                ["self"], //self.value (normal access)
                ["if", "let"] //if let value = self.value (shadowing)
            ]

            let isInstanceIdentifier = (type == .Identifier &&
                token.matches(instanceMemberNames, file: file))

            let isShadowingParameter = parameters.contains(value)

            let isViolation = (isInstanceIdentifier && !isShadowingParameter
                && !previous.suffix(matches: allowedSuffixes))

            guard isViolation else { continue }

            violations.append(StyleViolation(
                ruleDescription: self.dynamicType.description,
                severity: configuration.severity,
                location: Location(file: file, byteOffset: token.offset)
                )
            )
        }
        return violations
    }
}

extension SyntaxToken {
    func name(file: File) -> String {
        return file.contents.substring(self.offset, length: self.length)
    }
    func signature(file: File) -> String {
        let value = file.contents.substring(self.offset, length: self.length)

        guard file.contents.substring(self.offset + self.length, length: 1) == "("
            else { return value }

        //get value inside parens
        let remainder = file.contents
            .substring(self.offset + self.length + 1)
            .componentsSeparatedByString(")")[0]
        guard !remainder.isEmpty else { return "\(value)()" }

        let params = remainder
            .sanitizedParameters()
            .componentsSeparatedByString(",")

        var signature = ""
        for param in params {
            let pair = param.componentsSeparatedByString(":")
            if pair.count == 1 {
                signature += "_:"

            } else {
                let charSet = NSCharacterSet.whitespaceAndNewlineCharacterSet()
                let trimmed = pair[0].stringByTrimmingCharactersInSet(charSet)
                signature += "\(trimmed):"
            }
        }

        return "\(value)(\(signature))"
    }
    func matches(members: [String], file: File) -> Bool {
        let signature = self.signature(file)
        return members.contains(signature)
    }
}

extension File {
    func members(declarations: [SwiftDeclarationKind]) -> [[String: SourceKitRepresentable]] {
        return self.members(self.structure.dictionary, declarations: declarations)
    }
    func members(
        dictionary: [String: SourceKitRepresentable],
        declarations: [SwiftDeclarationKind]) -> [[String: SourceKitRepresentable]] {

        let substructure = dictionary["key.substructure"] as? [SourceKitRepresentable] ?? []

        return substructure.flatMap { subItem -> [[String: SourceKitRepresentable]] in
            guard let subDict = subItem as? [String: SourceKitRepresentable],
                kindString = subDict["key.kind"] as? String,
                kind = SwiftDeclarationKind(rawValue: kindString)
                else { return [] }

            return self.members(subDict, declarations: declarations) +
                (declarations.contains(kind) ? [subDict] : [])
        }
    }
}

extension SequenceType where Generator.Element: Equatable {
    func suffix(matches items: [Generator.Element]) -> Bool {
        let suffix = Array(self.suffix(items.count))

        // swiftlint:disable control_statement
        for (a, b) in zip(suffix, items) {
            if a == b { return true }
        }
        return false
    }

    func suffix(matches items: [[Generator.Element]]) -> Bool {
        for test in items
            where self.suffix(matches: test) { return true }
        return false
    }
}

extension String {
    func sanitizedParameters() -> String {
        return self.stringByReplacingOccurrencesOfString(
            "\"(.*)\",|\"(.*)\"",
            withString: "x",
            options: .RegularExpressionSearch,
            range: nil
        )
    }
}
