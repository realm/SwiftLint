//
//  NestingRule.swift
//  SwiftLint
//
//  Created by JP Simard on 5/16/15.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct NestingRule: ASTRule, ConfigurationProviderRule {

    public var configuration = NestingConfiguration(typeLevelWarning: 1,
                                                    typeLevelError: nil,
                                                    statementLevelWarning: 5,
                                                    statementLevelError: nil)

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
            let (targetName, targetLevel) = typeKinds.contains(kind)
                ? ("Types", configuration.typeLevel) : ("Statements", configuration.statementLevel)
            if let severity = configuration.severity(with: targetLevel, for: level) {
                let threshold = configuration.threshold(with: targetLevel, for: severity)
                let pluralSuffix = threshold > 1 ? "s" : ""
                violations.append(StyleViolation(
                    ruleDescription: type(of: self).description,
                    severity: severity,
                    location: Location(file: file, byteOffset: offset),
                    reason: "\(targetName) should be nested at most \(threshold) level\(pluralSuffix) deep"))
            }
        }
        violations.append(contentsOf: dictionary.substructure
            .flatMap { subDict -> [(SwiftDeclarationKind, [String: SourceKitRepresentable])] in
                if let kind = (subDict.kind).flatMap(SwiftDeclarationKind.init) {
                    return [(kind, subDict)]
                }
                return []
            }.flatMap { kindAndSubdict -> [StyleViolation] in
                let (kind, subDict) = kindAndSubdict
                return validate(file: file, kind: kind, dictionary: subDict, level: level + 1)
            }
        )
        return violations
    }
}
