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

    func getCustomRules(_ extraConfig: [String:String] = [:]) -> (RegexConfiguration, CustomRules) {
        var config = ["regex": "pattern",
                      "match_kinds": "comment"]
        extraConfig.forEach { config[$0.0] = $0.1 }

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

    func getTestTextFile() -> File {
        return File(path: "\(bundlePath)/test.txt")!
    }
}

extension CustomRulesTests {
    static var allTests: [(String, (CustomRulesTests) -> () throws -> Void)] {
        return [
            ("testCustomRuleConfigurationSetsCorrectly",
                testCustomRuleConfigurationSetsCorrectly),
            ("testCustomRuleConfigurationThrows",
                testCustomRuleConfigurationThrows),
            ("testCustomRules",
                testCustomRules),
            ("testLocalDisableCustomRule",
                testLocalDisableCustomRule),
            ("testCustomRulesIncludedDefault",
                testCustomRulesIncludedDefault),
            ("testCustomRulesIncludedExcludesFile",
                testCustomRulesIncludedExcludesFile),
            ("testCustomRulesExcludedExcludesFile",
                testCustomRulesExcludedExcludesFile)
        ]
    }
}
