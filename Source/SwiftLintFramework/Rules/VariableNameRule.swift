//
//  VariableNameRule.swift
//  SwiftLint
//
//  Created by JP Simard on 2015-05-16.
//  Copyright (c) 2015 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework

public struct VariableNameRuleConfig: RuleConfiguration {
    var lengthConfig: RuleMinMaxConfig
    var excluded: [String]

    init(minWarning: Int, minError: Int, maxWarning: Int, maxError: Int, excluded: [String] = []) {
        lengthConfig = RuleMinMaxConfig(minWarning: minWarning,
                                          minError: minError,
                                        maxWarning: maxWarning,
                                          maxError: maxError)
        self.excluded = excluded
    }

    public mutating func setConfiguration(config: AnyObject) throws {
        try lengthConfig.setConfiguration(config)
        if let dict = config as? [String: AnyObject],
           let excluded = dict["excluded"] as? [String] {
                self.excluded = excluded
        }
    }

    public func isEqualTo(ruleConfiguration: RuleConfiguration) -> Bool {
        if let config = ruleConfiguration as? VariableNameRuleConfig {
            return lengthConfig == config.lengthConfig &&
                   zip(excluded, config.excluded).reduce(true) { $0 && ($1.0 == $1.1) }
        }
        return false
    }
}

public struct VariableNameRule: ASTRule, ConfigurationProviderRule {

    public var configuration = VariableNameRuleConfig(minWarning: 3,
                                                        minError: 2,
                                                      maxWarning: 40,
                                                        maxError: 60)

    public init() {}

    public static let description = RuleDescription(
        identifier: "variable_name",
        name: "Variable Name",
        description: "Variable name should only contain alphanumeric characters and " +
          "start with a lowercase character or should only contain capital letters. " +
          "In an exception to the above, variable names may start with a capital letter " +
          "when they are declared static and immutable.",
        nonTriggeringExamples: [
            "let myLet = 0",
            "var myVar = 0",
            "private let _myLet = 0",
            "class Abc { static let MyLet = 0 }",
            "let URL: NSURL? = nil"
        ],
        triggeringExamples: [
            "↓let MyLet = 0",
            "↓let _myLet = 0",
            "private ↓let myLet_ = 0",
            "↓let myExtremelyVeryVeryVeryVeryVeryVeryLongLet = 0",
            "↓var myExtremelyVeryVeryVeryVeryVeryVeryLongVar = 0",
            "private ↓let _myExtremelyVeryVeryVeryVeryVeryVeryLongLet = 0",
            "↓let i = 0",
            "↓var id = 0",
            "private ↓let _i = 0"
        ]
    )

    private func nameIsViolatingCase(name: String) -> Bool {
        let firstCharacter = name.substringToIndex(name.startIndex.successor())
        return firstCharacter.isUppercase() && !name.isUppercase()
    }

    public func validateFile(file: File, kind: SwiftDeclarationKind,
                             dictionary: [String: SourceKitRepresentable]) -> [StyleViolation] {
        // swiftlint:disable line_length
        return file.validateVariableName(dictionary, kind: kind).map { name, offset in
            if !configuration.excluded.contains(name) {
                let nameCharacterSet = NSCharacterSet(charactersInString: name)
                let description = self.dynamicType.description
                let location = Location(file: file, byteOffset: offset)
                if !NSCharacterSet.alphanumericCharacterSet().isSupersetOfSet(nameCharacterSet) {
                    return [StyleViolation(ruleDescription: description,
                        severity: .Error,
                        location: location,
                        reason: "Variable name should only contain alphanumeric characters: '\(name)'")]
                } else if kind != SwiftDeclarationKind.VarStatic && nameIsViolatingCase(name) {
                    return [StyleViolation(ruleDescription: description,
                        severity: .Error,
                        location: location,
                        reason: "Variable name should start with a lowercase character: '\(name)'")]
                } else if let severity = violationSeverity(forLength: name.characters.count) {
                    return [StyleViolation(ruleDescription: self.dynamicType.description,
                        severity: severity,
                        location: location,
                        reason: "Variable name should be between \(configuration.lengthConfig.min.warning.value) and " +
                        "\(configuration.lengthConfig.max.warning.value) characters in length: '\(name)'")]
                }
            }
            // swiftlint:enable line_length
            return []
        } ?? []
    }

    private func violationSeverity(forLength length: Int) -> ViolationSeverity? {
        if length < configuration.lengthConfig.min.error.value ||
           length > configuration.lengthConfig.max.error.value {
                return .Error
        } else if length < configuration.lengthConfig.min.warning.value ||
                  length > configuration.lengthConfig.max.warning.value {
                return .Warning
        } else {
            return nil
        }
    }
}
