//
//  VariableNameMinLengthRule.swift
//  SwiftLint
//
//  Created by Mickaël Morier on 04/11/2015.
//  Copyright © 2015 Realm. All rights reserved.
//

import SourceKittenFramework

public struct VariableNameMinLengthRule: ASTRule, ConfigurableRule {

    public init() { }

    public init?(config: AnyObject) {
        self.init()
        if let config = [Int].arrayOf(config) where !config.isEmpty {
            warning = RuleParameter(severity: .Warning, value: config[0])
            if config.count > 1 {
                error = RuleParameter(severity: .Error, value: config[1])
            }
        } else if let config = config as? [String: AnyObject] {
            if let warningNumber = config["warning"] as? Int {
                warning = RuleParameter(severity: .Warning, value: warningNumber)
            }
            if let errorNumber = config["error"] as? Int {
                error = RuleParameter(severity: .Error, value: errorNumber)
            }
            if let excluded = config["excluded"] as? [String] {
                self.excluded = excluded
            }
        } else {
            return nil
        }
    }

    public var excluded = [String]()
    private var warning = RuleParameter(severity: .Warning, value: 3)
    private var error = RuleParameter(severity: .Error, value: 2)

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
                             dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        return file.validateVariableName(dictionary, kind: kind).map { name, offset in
            if !excluded.contains(name) {
                let charCount = name.characters.count
                for parameter in [error, warning] where charCount < parameter.value {
                    return [StyleViolation(ruleDescription: self.dynamicType.description,
                        severity: parameter.severity,
                        location: Location(file: file, byteOffset: offset),
                        reason: "Variable name should be \(parameter.value) characters " +
                        "or more: currently \(charCount) characters")]
                }
            }
            return []
        } ?? []
    }

    public func isEqualTo(rule: ConfigurableRule) -> Bool {
        guard let rule = rule as? VariableNameMinLengthRule else {
            return false
        }

        // Need to use alternate method to compare excluded due to apparent bug in
        // the way that SwiftXPC compares [String]
        return error == rule.error &&
               warning == rule.warning &&
               zip(excluded, rule.excluded).reduce(true) { $0 && ($1.0 == $1.1) }
    }
}
