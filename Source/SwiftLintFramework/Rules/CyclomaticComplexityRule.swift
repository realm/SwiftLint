//
//  CyclomaticComplexityRule.swift
//  SwiftLint
//
//  Created by Denis Lebedev on 24/01/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct CyclomaticComplexityRule: ASTRule, ConfigProviderRule {
    public var config = SeverityLevelsConfig(warning: 10, error: 20)

    public init() {}

    public static let description = RuleDescription(
        identifier: "cyclomatic_complexity",
        name: "Cyclomatic Complexity",
        description: "Complexity of function bodies should be limited.",
        nonTriggeringExamples: [
            "func f1() {\nif true {\nfor _ in 1..5 { } }\nif false { }\n}",
            "func f3() {while true {}}",
        ],
        triggeringExamples: [
            "func f1() {\nif true { if true{ if false {} }}\nif false { }\nlet i = 0\n" +
            "switch i {\ncase 1: break\ncase 2: break\ncase3: break\ndefault: break\n}\n" +
            "for _ in 1...5 { guard true else { return } }}"
        ]
    )

    public func validateFile(file: File,
        kind: SwiftDeclarationKind,
        dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {

            if !functionKinds.contains(kind) {
                return []
            }

            let substructure = dictionary["key.substructure"] as? [SourceKitRepresentable] ?? []
            let complexity = measureComplexity(substructure) + 1

            for parameter in config.params where complexity > parameter.value {
                let offset = Int(dictionary["key.offset"] as? Int64 ?? 0)
                return [StyleViolation(ruleDescription: self.dynamicType.description,
                    severity: parameter.severity,
                    location: Location(file: file, characterOffset: offset),
                    reason: "Function should have complexity \(config.warning) or less: " +
                    "currently complexity equals \(complexity)")]
            }

            return []
    }

    private func measureComplexity(substructure: [SourceKitRepresentable]) -> Int {
        var complexity = 0

        for s in substructure {
            guard let subItem = s as? [String: SourceKitRepresentable],
            let key = subItem["key.kind"] as? String else {
                continue
            }

            if complexityStatements.contains(key) {
                complexity++
            }

            if let subSubItem = subItem["key.substructure"] as? [SourceKitRepresentable] {
                complexity += measureComplexity(subSubItem)
            }
        }

        return complexity
    }

    private let complexityStatements = [
        "source.lang.swift.stmt.foreach",
        "source.lang.swift.stmt.if",
        "source.lang.swift.stmt.switch",
        "source.lang.swift.stmt.case",
        "source.lang.swift.stmt.guard",
        "source.lang.swift.stmt.for",
        "source.lang.swift.stmt.repeatwhile",
        "source.lang.swift.stmt.while"
    ]

    private let functionKinds: [SwiftDeclarationKind] = [
        .FunctionAccessorAddress,
        .FunctionAccessorDidset,
        .FunctionAccessorGetter,
        .FunctionAccessorMutableaddress,
        .FunctionAccessorSetter,
        .FunctionAccessorWillset,
        .FunctionConstructor,
        .FunctionDestructor,
        .FunctionFree,
        .FunctionMethodClass,
        .FunctionMethodInstance,
        .FunctionMethodStatic,
        .FunctionOperator,
        .FunctionSubscript
    ]

}
