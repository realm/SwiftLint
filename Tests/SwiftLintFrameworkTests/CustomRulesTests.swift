//
//  CustomRulesTests.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/21/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import SourceKittenFramework
@testable import SwiftLintFramework
import XCTest

class CustomRulesTests: XCTestCase {

    func testCustomRuleConfigurationSetsCorrectly() {
        let configDict = ["my_custom_rule": ["name": "MyCustomRule",
            "message": "Message",
            "regex": "regex",
            "match_kinds": "comment",
            "severity": "error"]]
        var comp = RegexConfiguration(identifier: "my_custom_rule")
        comp.name = "MyCustomRule"
        comp.message = "Message"
        comp.regex = regex("regex")
        comp.severityConfiguration = SeverityConfiguration(.error)
        comp.matchKinds = Set([SyntaxKind.comment])
        var compRules = CustomRulesConfiguration()
        compRules.customRuleConfigurations = [comp]
        do {
            var configuration = CustomRulesConfiguration()
            try configuration.apply(configuration: configDict)
            XCTAssertEqual(configuration, compRules)
        } catch {
            XCTFail("Did not configure correctly")
        }
    }

    func testCustomRuleConfigurationThrows() {
        let config = 17
        var customRulesConfig = CustomRulesConfiguration()
        checkError(ConfigurationError.unknownConfiguration) {
            try customRulesConfig.apply(configuration: config)
        }
    }

    func testCustomRuleConfigurationIgnoreInvalidRules() throws {
        let configDict = [
            "my_custom_rule": ["name": "MyCustomRule",
                               "message": "Message",
                               "regex": "regex",
                               "match_kinds": "comment",
                               "severity": "error"],
            "invalid_rule": ["name": "InvalidRule"] // missing `regex`
        ]
        var customRulesConfig = CustomRulesConfiguration()
        try customRulesConfig.apply(configuration: configDict)

        XCTAssertEqual(customRulesConfig.customRuleConfigurations.count, 1)

        let identifier = customRulesConfig.customRuleConfigurations.first?.description.identifier
        XCTAssertEqual(identifier, "my_custom_rule")
    }

    func testCustomRules() {
        let (regexConfig, customRules) = getCustomRules()

        let file = File(contents: "// My file with\n// a pattern")
        XCTAssertEqual(customRules.validate(file: file),
                       [StyleViolation(ruleDescription: regexConfig.description,
                                       severity: .warning,
                                       location: Location(file: nil, line: 2, character: 6),
                                       reason: regexConfig.message)])
    }

    func testLocalDisableCustomRule() {
        let (_, customRules) = getCustomRules()
        let file = File(contents: "//swiftlint:disable custom \n// file with a pattern")
        XCTAssertEqual(customRules.validate(file: file), [])
    }

    func testLocalDisableCustomRuleWithMultipleRules() {
        let (configs, customRules) = getCustomRulesWithTwoRules()
        let file = File(contents: "//swiftlint:disable \(configs.1.identifier) \n// file with a pattern")
        XCTAssertEqual(customRules.validate(file: file),
                       [StyleViolation(ruleDescription: configs.0.description,
                                       severity: .warning,
                                       location: Location(file: nil, line: 2, character: 16),
                                       reason: configs.0.message)])
    }

    func testCustomRulesIncludedDefault() {
        // Violation detected when included is omitted.
        let (_, customRules) = getCustomRules()
        let violations = customRules.validate(file: getTestTextFile())
        XCTAssertEqual(violations.count, 1)
    }

    func testCustomRulesIncludedExcludesFile() {
        var (regexConfig, customRules) = getCustomRules(["included": "\\.yml$"])

        var customRuleConfiguration = CustomRulesConfiguration()
        customRuleConfiguration.customRuleConfigurations = [regexConfig]
        customRules.configuration = customRuleConfiguration

        let violations = customRules.validate(file: getTestTextFile())
        XCTAssertEqual(violations.count, 0)
    }

    func testCustomRulesExcludedExcludesFile() {
        var (regexConfig, customRules) = getCustomRules(["excluded": "\\.txt$"])

        var customRuleConfiguration = CustomRulesConfiguration()
        customRuleConfiguration.customRuleConfigurations = [regexConfig]
        customRules.configuration = customRuleConfiguration

        let violations = customRules.validate(file: getTestTextFile())
        XCTAssertEqual(violations.count, 0)
    }

    private func getCustomRules(_ extraConfig: [String: String] = [:]) -> (RegexConfiguration, CustomRules) {
        var config = ["regex": "pattern",
                      "match_kinds": "comment"]
        extraConfig.forEach { config[$0] = $1 }

        var regexConfig = RegexConfiguration(identifier: "custom")
        do {
            try regexConfig.apply(configuration: config)
        } catch {
            XCTFail("Failed regex config")
        }

        var customRuleConfiguration = CustomRulesConfiguration()
        customRuleConfiguration.customRuleConfigurations = [regexConfig]

        var customRules = CustomRules()
        customRules.configuration = customRuleConfiguration
        return (regexConfig, customRules)
    }

    private func getCustomRulesWithTwoRules() -> ((RegexConfiguration, RegexConfiguration), CustomRules) {
        let config1 = ["regex": "pattern",
                      "match_kinds": "comment"]

        var regexConfig1 = RegexConfiguration(identifier: "custom1")
        do {
            try regexConfig1.apply(configuration: config1)
        } catch {
            XCTFail("Failed regex config")
        }

        let config2 = ["regex": "something",
                       "match_kinds": "comment"]

        var regexConfig2 = RegexConfiguration(identifier: "custom2")
        do {
            try regexConfig2.apply(configuration: config2)
        } catch {
            XCTFail("Failed regex config")
        }

        var customRuleConfiguration = CustomRulesConfiguration()
        customRuleConfiguration.customRuleConfigurations = [regexConfig1, regexConfig2]

        var customRules = CustomRules()
        customRules.configuration = customRuleConfiguration
        return ((regexConfig1, regexConfig2), customRules)
    }

    private func getTestTextFile() -> File {
        return File(path: "\(bundlePath)/test.txt")!
    }
}
