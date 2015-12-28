//
//  VariableNameMinLengthRule.swift
//  SwiftLint
//
//  Created by Mickaël Morier on 04/11/2015.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework
import SwiftXPC

public struct VariableNameMinLengthRule: ASTRule, ParameterizedRule {
    public init() {
        self.init(parameters: [
            RuleParameter(severity: .Warning, value: 3),
            RuleParameter(severity: .Error, value: 2)
        ])
    }

    public init(parameters: [RuleParameter<Int>]) {
        self.parameters = parameters
    }

    public let parameters: [RuleParameter<Int>]

    public static let description = RuleDescription(
        identifier: "variable_name_min_length",
        name: "Variable Name Min Length Rule",
        description: "Variable name should not be too short.",
        nonTriggeringExamples: [
            "let myLet = 0",
            "var myVar = 0",
            "private let _myLet = 0"
        ],
        triggeringExamples: [
            "↓let i = 0",
            "↓var id = 0",
            "private ↓let _i = 0"
        ]
    )

    public func validateFile(file: File, kind: SwiftDeclarationKind,
                             dictionary: XPCDictionary) -> [StyleViolation] {
        return file.validateVariableName(dictionary, kind: kind).map { name, offset in
            let charCount = name.characters.count
            for parameter in parameters.reverse() where charCount < parameter.value {
                return [StyleViolation(ruleDescription: self.dynamicType.description,
                    severity: parameter.severity,
                    location: Location(file: file, byteOffset: offset),
                    reason: "Variable name should be \(parameter.value) characters " +
                            "or more: currently \(charCount) characters")]
            }
            return []
        } ?? []
    }
}
