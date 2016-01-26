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
            Trigger("func f1() {\nif true {\nfor _ in 1..5 { } }\nif false { }\n}"),
            Trigger("func f3() {while true {}}"),
        ],
        triggeringExamples: [
            Trigger("func f1() {\n  if true {\n    if true {\n      if false {}\n    }\n" +
                "  }\n  if false {}\n  let i = 0\n\n  switch i {\n  case 1: break\n" +
                "  case 2: break\n  case 3: break\n  default: break\n  }\n\n" +
                "  for _ in 1...5 {\n    guard true else {\n      return\n    }\n  }\n}\n")
        ]
    )

    public func validateFile(file: File, kind: SwiftDeclarationKind,
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
        return substructure.reduce(0) { complexity, subItem in
            guard let subDict = subItem as? [String: SourceKitRepresentable],
                      key = subDict["key.kind"] as? String else {
                return complexity
            }
            if let subSubItem = subDict["key.substructure"] as? [SourceKitRepresentable] {
                return complexity +
                    Int(complexityStatements.contains(key)) +
                    measureComplexity(subSubItem)
            }
            return complexity + Int(complexityStatements.contains(key))
        }
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
