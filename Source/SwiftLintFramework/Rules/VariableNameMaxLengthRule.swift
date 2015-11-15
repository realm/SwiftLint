//
//  VariableNameMaxLengthRule.swift
//  SwiftLint
//
//  Created by Mickaël Morier on 05/11/2015.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework
import SwiftXPC

public struct VariableNameMaxLengthRule: ASTRule, ParameterizedRule {
    public init() {
        self.init(parameters: [
            RuleParameter(severity: .Warning, value: 40),
            RuleParameter(severity: .Error, value: 60)
            ])
    }

    public init(parameters: [RuleParameter<Int>]) {
        self.parameters = parameters
    }

    public let parameters: [RuleParameter<Int>]

    public static let description = RuleDescription(
        identifier: "variable_name_max_length",
        name: "Variable Name Max Length Rule",
        description: "Variable name should be 40 characters or less.",
        nonTriggeringExamples: [
            "let myLet = 0",
            "var myVar = 0",
            "private let _myLet = 0"
        ],
        triggeringExamples: [
            "let myExtremelyVeryVeryVeryVeryVeryVeryLongLet = 0",
            "var myExtremelyVeryVeryVeryVeryVeryVeryLongVar = 0",
            "private let _myExtremelyVeryVeryVeryVeryVeryVeryLongLet = 0"
        ]
    )

    public func validateFile(file: File,
        kind: SwiftDeclarationKind,
        dictionary: XPCDictionary) -> [StyleViolation] {
            let variableKinds: [SwiftDeclarationKind] = [
                .VarClass,
                .VarGlobal,
                .VarInstance,
                .VarLocal,
                .VarParameter,
                .VarStatic
            ]
            if !variableKinds.contains(kind) {
                return []
            }
            guard let name = dictionary["key.name"] as? String,
                let offset = (dictionary["key.offset"] as? Int64).flatMap({ Int($0) }) else {
                    return []
            }
            return name.violationsForNameAtLocation(Location(file: file, offset: offset),
                dictionary: dictionary, ruleDescription: self.dynamicType.description,
                parameters: self.parameters)
    }
}

extension String {
    private func violationsForNameAtLocation(location: Location, dictionary: XPCDictionary,
        ruleDescription: RuleDescription, parameters: [RuleParameter<Int>]) -> [StyleViolation] {
            if characters.first == "$" {
                // skip block variables
                return []
            }
            let name = nameStrippingLeadingUnderscoreIfPrivate(dictionary)
            for parameter in parameters.reverse() where name.characters.count > parameter.value {
                return [StyleViolation(ruleDescription: ruleDescription,
                    severity: parameter.severity,
                    location: location,
                    reason: "Variable name should be \(parameter.value) characters " +
                            "or less: currently \(name.characters.count) characters")]
            }
            return []
    }
}
