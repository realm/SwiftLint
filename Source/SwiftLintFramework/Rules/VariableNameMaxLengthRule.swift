//
//  VariableNameMaxLengthRule.swift
//  SwiftLint
//
//  Created by Mickaël Morier on 05/11/2015.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework
import SwiftXPC

public struct VariableNameMaxLengthRule: ASTRule, ParameterizedRule, ConfigurableRule {
    public init() {
        self.init(parameters: [
            RuleParameter(severity: .Warning, value: 40),
            RuleParameter(severity: .Error, value: 60)
        ])
    }

    public init(config: [String : AnyObject]) {
        if let array = config[self.dynamicType.description.identifier] as? [Int] {
            self.init(parameters: RuleParameter<Int>.ruleParametersFromArray(array))
        } else {
            self.init()
        }
    }

    public init(parameters: [RuleParameter<Int>]) {
        self.parameters = parameters
    }

    public let parameters: [RuleParameter<Int>]

    public static let description = RuleDescription(
        identifier: "variable_name_max_length",
        name: "Variable Name Max Length Rule",
        description: "Variable name should not be too long.",
        nonTriggeringExamples: [
            "let myLet = 0",
            "var myVar = 0",
            "private let _myLet = 0"
        ],
        triggeringExamples: [
            "↓let myExtremelyVeryVeryVeryVeryVeryVeryLongLet = 0",
            "↓var myExtremelyVeryVeryVeryVeryVeryVeryLongVar = 0",
            "private ↓let _myExtremelyVeryVeryVeryVeryVeryVeryLongLet = 0"
        ]
    )

    public func validateFile(file: File, kind: SwiftDeclarationKind,
                             dictionary: XPCDictionary) -> [StyleViolation] {
        return file.validateVariableName(dictionary, kind: kind).map { name, offset in
            let charCount = name.characters.count
            for parameter in parameters.reverse() where charCount > parameter.value {
                return [StyleViolation(ruleDescription: self.dynamicType.description,
                    severity: parameter.severity,
                    location: Location(file: file, byteOffset: offset),
                    reason: "Variable name should be \(parameter.value) characters " +
                            "or less: currently \(charCount) characters")]
            }
            return []
        } ?? []
    }
}
