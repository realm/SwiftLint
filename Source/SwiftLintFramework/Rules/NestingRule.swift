//
//  NestingRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import SourceKittenFramework
import SwiftXPC

public struct NestingRule: ASTRule {
    public init() {}

    public let identifier = "nesting"

    public func validateFile(file: File) -> [StyleViolation] {
        return validateFile(file, dictionary: file.structure.dictionary)
    }

    public func validateFile(file: File, dictionary: XPCDictionary) -> [StyleViolation] {
        return (dictionary["key.substructure"] as? XPCArray ?? []).flatMap { subItem in
            var violations = [StyleViolation]()
            if let subDict = subItem as? XPCDictionary,
                let kindString = subDict["key.kind"] as? String,
                let kind = flatMap(kindString, { SwiftDeclarationKind(rawValue: $0) }) {
                    violations.extend(validateFile(file, dictionary: subDict))
                    violations.extend(validateFile(file, kind: kind, dictionary: subDict))
            }
            return violations
        }
    }

    public func validateFile(file: File,
        kind: SwiftDeclarationKind,
        dictionary: XPCDictionary) -> [StyleViolation] {
        return self.validateFile(file, kind: kind, dictionary: dictionary, level: 0)
    }

    func validateFile(file: File,
        kind: SwiftDeclarationKind,
        dictionary: XPCDictionary,
        level: Int) -> [StyleViolation] {
        var violations = [StyleViolation]()
        let typeKinds: [SwiftDeclarationKind] = [
            .Class,
            .Struct,
            .Typealias,
            .Enum,
            .Enumelement
        ]
        if let offset = flatMap(dictionary["key.offset"] as? Int64, { Int($0) }) {
            if level > 1 && contains(typeKinds, kind) {
                violations.append(StyleViolation(type: .Nesting,
                    location: Location(file: file, offset: offset),
                    reason: "Types should be nested at most 1 level deep"))
            } else if level > 5 {
                violations.append(StyleViolation(type: .Nesting,
                    location: Location(file: file, offset: offset),
                    reason: "Statements should be nested at most 5 levels deep"))
            }
        }
        let substructure = dictionary["key.substructure"] as? XPCArray ?? []
        violations.extend(compact(substructure.map { subItem in
            let subDict = subItem as? XPCDictionary
            let kindString = subDict?["key.kind"] as? String
            let kind = flatMap(kindString) { kindString in
                return SwiftDeclarationKind(rawValue: kindString)
            }
            if let kind = kind, subDict = subDict {
                return (kind, subDict)
            }
            return nil
        } as [(SwiftDeclarationKind, XPCDictionary)?]).flatMap { (kind, dict) in
            return validateFile(file, kind: kind, dictionary: dict, level: level + 1)
        })
        return violations
    }

    public let example = RuleExample(
        ruleName: "Nesting Rule",
        ruleDescription: "Types should be nested at most 1 level deep, " +
        "and statements should be nested at most 5 levels deep.",
        nonTriggeringExamples: ["class", "struct", "enum"].flatMap { kind in
            ["\(kind) Class0 { \(kind) Class1 {} }\n",
                "func func0() {\nfunc func1() {\nfunc func2() {\nfunc func3() {\nfunc func4() { " +
                "func func5() {\n}\n}\n}\n}\n}\n}\n"]
        },
        triggeringExamples: ["class", "struct", "enum"].map { kind in
            "\(kind) Class0 { \(kind) Class1 { \(kind) Class2 {} } }\n"
            } + [
            "func func0() {\nfunc func1() {\nfunc func2() {\nfunc func3() {\nfunc func4() { " +
            "func func5() {\nfunc func6() {\n}\n}\n}\n}\n}\n}\n}\n"
            ]
    )
}
