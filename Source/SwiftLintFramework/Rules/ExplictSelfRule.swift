//
//  ExplictSelfRule.swift
//  SwiftLint
//
//  Created by Ian Keen on 2016-10-06.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ExplicitSelfRule: ASTRule, OptInRule, ConfigurationProviderRule {
    public var configuration = SeverityConfiguration(.Error)

    public init() { }

    public static let description = RuleDescription(
        identifier: "explicitSelf",
        name: "Explict Self",
        description: "Require explicit self for instance members",
        nonTriggeringExamples: [
            "class Good1 { let value: Int = 42; var property: Int { return self.value } }",
            "class Good2 { let value: Int = 42; func function() -> Int { return self.value } }",
            "class Good3 { let value: Int; init() { self.value = 42 } }",
        ],
        triggeringExamples: [
            "class Bad1 { let value: Int = 42; var property: Int { return value } }",
            "class Bad2 { let value: Int = 42; func function() -> Int { return value } }",
            "class Bad3 { let value: Int; init() { value = 42 } }",
        ]
    )

    public func validateFile(
        file: File,
        kind: SwiftDeclarationKind,
        dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {

        //only check kinds that might use instance members
        let types: [SwiftDeclarationKind] = [
            .FunctionMethodInstance,
            .VarInstance,
        ]
        guard types.contains(kind) else { return [] }

        //build a set of instance memebers
        let memberTypes: [SwiftDeclarationKind] = [
            .FunctionMethodInstance,
            .VarInstance,
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

        var violations: [StyleViolation] = []

        var previous: [String] = []
        for token in tokens {
            guard let type = SyntaxKind(rawValue: token.type) else { continue }

            let value = file.contents.substring(token.offset, length: token.length)
            defer { previous.append(value) }

            let allowedSuffixes: [[String]] = [
                ["self"], //self.value (normal access)
                ["if", "let"] //if let value = self.value (shadowing)
            ]

            let isInstanceIdentifier = (type == .Identifier && instanceMemberNames.contains(value))

            if isInstanceIdentifier && !previous.suffix(matches: allowedSuffixes) {
                violations.append(StyleViolation(
                    ruleDescription: self.dynamicType.description,
                    severity: configuration.severity,
                    location: Location(file: file, byteOffset: token.offset)
                    )
                )
            }
        }

        return violations
    }
}

extension File {
    func members(declarations: [SwiftDeclarationKind]) -> [[String: SourceKitRepresentable]] {
        return self.members(self, dictionary: self.structure.dictionary, declarations: declarations)
    }
    private func members(
        file: File,
        dictionary: [String: SourceKitRepresentable],
        declarations: [SwiftDeclarationKind]) -> [[String: SourceKitRepresentable]] {

        let substructure = dictionary["key.substructure"] as? [SourceKitRepresentable] ?? []

        return substructure.flatMap { subItem -> [[String: SourceKitRepresentable]] in
            guard let subDict = subItem as? [String: SourceKitRepresentable],
                kindString = subDict["key.kind"] as? String,
                kind = SwiftDeclarationKind(rawValue: kindString)
                else { return [] }

            return self.members(file, dictionary: subDict, declarations: declarations) +
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
