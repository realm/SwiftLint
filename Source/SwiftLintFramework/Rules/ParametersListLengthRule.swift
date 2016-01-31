//
//  ParemeterListLengthRule.swift
//  SwiftLint
//
//  Created by Denis Lebedev on 26/01/2016.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct ParametersListLengthRule: ASTRule, ConfigProviderRule {
    public var config = SeverityLevelsConfig(warning: 5, error: 8)

    public init() {}

    public static let description = RuleDescription(
        identifier: "parameters_list_length",
        name: "Parameter List Length",
        description: "Length of parameter list should be short.",
        nonTriggeringExamples: [
            "func f2(p1: Int, p2: Int) { }",
            "func f(a: Int, b: Int, c: Int, d: Int, x: Int = 42) {}",
            "func f(a: [Int], b: Int, c: Int, d: Int, f: Int) -> [Int] {\n" +
            "let s = a.flatMap { $0 as? [String: Int] } ?? []}}"
        ],
        triggeringExamples: [
            "func f(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int) {}",
            "func f(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int = 2, g: Int) {}",
        ]
    )

    public func validateFile(file: File, kind: SwiftDeclarationKind,
        dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
            if !functionKinds.contains(kind) {
                return []
            }

            let nameOffset = Int(dictionary["key.nameoffset"] as? Int64 ?? 0)
            let length = Int(dictionary["key.namelength"] as? Int64 ?? 0)
            let substructure = dictionary["key.substructure"] as? [SourceKitRepresentable] ?? []

            let allParams = allFuncParameters(substructure, offset: nameOffset, length: length)
            let defaultParams = defaultFuncParameters(file, offset: nameOffset, length: length)

            let parametersCount = allParams - defaultParams

            for parameter in config.params where parametersCount > parameter.value {
                let offset = Int(dictionary["key.offset"] as? Int64 ?? 0)
                return [StyleViolation(ruleDescription: self.dynamicType.description,
                    severity: parameter.severity,
                    location: Location(file: file, byteOffset: offset),
                    reason: "{Parameters list should have \(config.warning) or less parameters: " +
                    "currently it has \(parametersCount)")]
            }

            return []
    }

    private func allFuncParameters(structure: [SourceKitRepresentable],
        offset: Int, length: Int) -> Int {

            var count = 0
            for e in structure {
                guard let subDict = e as? [String: SourceKitRepresentable],
                    key = subDict["key.kind"] as? String,
                    paramOffset = subDict["key.offset"] as? Int64 else {
                        continue
                }

                guard offset..<offset+length ~= Int(paramOffset) else {
                    return count
                }

                if SwiftDeclarationKind(rawValue: key) == .VarParameter {
                    count += 1
                }
            }
            return count
    }

    private func defaultFuncParameters(file: File, offset: Int, length: Int) -> Int {
        return (file.contents as NSString)
            .substringWithByteRange(start: offset, length: length)?
            .characters.filter { $0 == "=" }.count ?? 0
    }

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
