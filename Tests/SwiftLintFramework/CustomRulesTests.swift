//
//  CustomRulesTests.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/21/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import Foundation
import XCTest
@testable import SwiftLintFramework
import SourceKittenFramework

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
        comp.regex = NSRegularExpression.forcePattern("regex")
        comp.severityConfiguration = SeverityConfiguration(.Error)
        comp.matchKinds = Set([SyntaxKind.Comment])
        var compRules = CustomRulesConfiguration()
        compRules.customRuleConfigurations = [comp]
        do {
            var configuration = CustomRulesConfiguration()
            try configuration.applyConfiguration(configDict)
            XCTAssertEqual(configuration, compRules)
        } catch {
            XCTFail("Did not configure correctly")
        }
    }

    func testCustomRuleConfigurationThrows() {
        let config = 17
        var customRulesConfig = CustomRulesConfiguration()
        checkError(ConfigurationError.UnknownConfiguration) {
            try customRulesConfig.applyConfiguration(config)
        }
    }

    func testCustomRules() {
        let (regexConfig, customRules) = getCustomRules()

        let file = File(contents: "// My file with\n// a pattern")
        XCTAssertEqual(customRules.validateFile(file),
                       [StyleViolation(ruleDescription: regexConfig.description,
                        severity: .Warning,
                        location: Location(file: nil, line: 2, character: 6),
                        reason: regexConfig.message)])
    }

    func testLocalDisableCustomRule() {
        let (_, customRules) = getCustomRules()
        let file = File(contents: "//swiftlint:disable custom \n// file with a pattern")
        XCTAssertEqual(customRules.validateFile(file),
                       [])
    }

    func testCustomRulesIncludedDefault() {
        // Violation detected when included is omitted.
        let (_, customRules) = getCustomRules()
        let violations = customRules.validateFile(getTestTextFile())
        XCTAssertEqual(violations.count, 1)
    }

    func testCustomRulesIncludedExcludesFile() {
        var (regexConfig, customRules) = getCustomRules(["included": "\\.yml$"])

        var customRuleConfiguration = CustomRulesConfiguration()
        customRuleConfiguration.customRuleConfigurations = [regexConfig]
        customRules.configuration = customRuleConfiguration

        let violations = customRules.validateFile(getTestTextFile())
        XCTAssertEqual(violations.count, 0)
    }

    func getCustomRules(extraConfig: [String:String] = [:]) -> (RegexConfiguration, CustomRules) {
        var config = ["regex": "pattern",
                      "match_kinds": "comment"]
        extraConfig.forEach { config[$0] = $1 }

        var regexConfig = RegexConfiguration(identifier: "custom")
        do {
            try regexConfig.applyConfiguration(config)
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
        #if SWIFT_PACKAGE
            let path: String = "Tests/SwiftLintFramework/Resources/test.txt"
                .absolutePathRepresentation()
            return File(path: path)!
        #else
            let testBundle = NSBundle(forClass: self.dynamicType)
            let path: String? = testBundle.pathForResource("test", ofType: "txt")
            if path != nil {
                return File(path: path!)!
            }
        #endif
        fatalError("Could not load test.txt")
    }
}
