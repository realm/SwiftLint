//
//  NestingRule.swift
//  SwiftLint
//
//  Created by JP Simard on 5/16/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct NestingRule: ASTRule, ConfigurationProviderRule {

    public var configuration = SeverityConfiguration(.warning)

    public init() {}

    public static let description = RuleDescription(
        identifier: "nesting",
        name: "Nesting",
        description: "Types should be nested at most 1 level deep, " +
        "and statements should be nested at most 5 levels deep.",
        nonTriggeringExamples: ["class", "struct", "enum"].flatMap { kind in
            ["\(kind) Class0 { \(kind) Class1 {} }\n",
                "func func0() {\nfunc func1() {\nfunc func2() {\nfunc func3() {\nfunc func4() { " +
                "func func5() {\n}\n}\n}\n}\n}\n}\n"]
        } + ["enum Enum0 { enum Enum1 { case Case } }"],
        triggeringExamples: ["class", "struct", "enum"].map { kind in
            "\(kind) A { \(kind) B { ↓\(kind) C {} } }\n"
        } + [
                "func func0() {\nfunc func1() {\nfunc func2() {\nfunc func3() {\nfunc func4() { " +
                "func func5() {\n↓func func6() {\n}\n}\n}\n}\n}\n}\n}\n"
        ]
    )

    public func validate(file: File, kind: SwiftDeclarationKind,
                         dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        return validate(file: file, kind: kind, dictionary: dictionary, level: 0)
    }

    private func validate(file: File, kind: SwiftDeclarationKind, dictionary: [String: SourceKitRepresentable],
                          level: Int) -> [StyleViolation] {
        var violations = [StyleViolation]()
        let typeKinds = SwiftDeclarationKind.typeKinds()
        if let offset = dictionary.offset {
            if level > 1 && typeKinds.contains(kind) {
                violations.append(StyleViolation(ruleDescription: type(of: self).description,
                    severity: configuration.severity,
                    location: Location(file: file, byteOffset: offset),
                    reason: "Types should be nested at most 1 level deep"))
            } else if level > 5 {
                violations.append(StyleViolation(ruleDescription: type(of: self).description,
                    severity: configuration.severity,
                    location: Location(file: file, byteOffset: offset),
                    reason: "Statements should be nested at most 5 levels deep"))
            }
        }
        violations.append(contentsOf: dictionary.substructure.flatMap { subDict in
            if let kind = (subDict.kind).flatMap(SwiftDeclarationKind.init) {
                return (kind, subDict)
            }
            return nil
        }.flatMap { kind, subDict in
            return validate(file: file, kind: kind, dictionary: subDict, level: level + 1)
        })
        return violations
    }
}
