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
            "func f1() {\nif true {\nfor _ in 1..5 { } }\nif false { }\n}"
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

            let functionKinds: [SwiftDeclarationKind] = [
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
            if !functionKinds.contains(kind) {
                return []
            }

            let substructure = dictionary["key.substructure"] as? [SourceKitRepresentable] ?? []
            let complexity = measureComplexity(substructure)

            for parameter in config.params where complexity >= parameter.value {
                let offset = Int(dictionary["key.offset"] as? Int64 ?? 0)
                return [StyleViolation(ruleDescription: self.dynamicType.description,
                    severity: parameter.severity,
                    location: Location(file: file, characterOffset: offset),
                    reason: "Function should have complexity \(config.warning) or less: " +
                    "currently complexity equal \(complexity)")]
            }

            return []
    }

    private func measureComplexity(substructure: [SourceKitRepresentable], count: Int = 0) -> Int {

        let statements = [
            "source.lang.swift.stmt.foreach",
            "source.lang.swift.stmt.if",
            "source.lang.swift.stmt.switch",
            "source.lang.swift.stmt.case",
            "source.lang.swift.stmt.guard"
        ]

        var counter = count

        for e in substructure {
            let v = e as? [String: SourceKitRepresentable] ?? [:]

            if let key = v["key.kind"] as? String where statements.contains(key) {
                counter++
            }
            counter += measureComplexity(v["key.substructure"] as? [SourceKitRepresentable] ?? [])
        }

        return counter
    }

}
