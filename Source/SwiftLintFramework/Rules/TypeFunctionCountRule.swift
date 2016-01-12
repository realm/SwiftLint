//
//  TypeFunctionCountRule.swift
//  SwiftLint
//
//  Created by Brandon Kobilansky on 1/11/16.
//  Copyright (c) 2016 Realm. All rights reserved.
//

import SourceKittenFramework
import SwiftXPC

public struct TypeFunctionCountRule: ASTRule, ParameterizedRule {
    public init() {
        self.init(parameters: [
            RuleParameter(severity: .Warning, value: 8),
            RuleParameter(severity: .Error, value: 10)
            ])
    }

    public init(parameters: [RuleParameter<Int>]) {
        self.parameters = parameters
    }

    public let parameters: [RuleParameter<Int>]

    public static let description = RuleDescription(
        identifier: "type_function_count",
        name: "Type Function Count",
        description: "Types should not contain too many functions.",
        nonTriggeringExamples: [
            "struct Foo { static func foo() {} }",
            "class Foo { class func foo() {} }",
            "enum Foo { func foo() {} }",
        ],
        triggeringExamples: TypeFunctionCountRule.triggeringExamples()
    )

    public func validateFile(file: File,
        kind: SwiftDeclarationKind,
        dictionary: XPCDictionary) -> [StyleViolation] {
            let typeKinds: [SwiftDeclarationKind] = [.Class, .Struct, .Enum]

            if !typeKinds.contains(kind) {
                return []
            }

            let functionKinds: [SwiftDeclarationKind] = [
                .FunctionMethodInstance,
                .FunctionMethodClass,
                .FunctionMethodStatic
            ]

            if let substructure = dictionary["key.substructure"] as? XPCArray {
                let functions = substructure.filter { xpcItem in
                    if let item = xpcItem as? XPCDictionary,
                        keyKind = item["key.kind"] as? String,
                        functionKind = SwiftDeclarationKind(rawValue: keyKind) {
                            return functionKinds.contains(functionKind)
                    }
                    return false
                }

                for parameter in parameters.reverse() where functions.count > parameter.value {
                    let offset = (dictionary["key.nameoffset"] as? Int64).flatMap({Int($0)}) ?? 0
                    return [StyleViolation(ruleDescription: self.dynamicType.description,
                        severity: parameter.severity,
                        location: Location(file: file, characterOffset: offset),
                        reason: "Type should contain \(parameter.value) functions or less: " +
                        "currently contains \(functions.count)")]
                }
            }
            return []
    }

    // MARK: - Private Methods

    private static func triggeringExamples() -> [String] {
        let functions = "static func foo() {} class func foo() {} func foo() {}"
        let repeatedFunctions = Repeat(count: 10, repeatedValue: functions).joinWithSeparator("")
        return ["struct", "class", "enum"].map {
            return "\($0) Foo { \(repeatedFunctions) }"
        }
    }
}
