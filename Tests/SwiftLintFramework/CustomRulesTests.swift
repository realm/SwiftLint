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
        var regexConfig = RegexConfiguration(identifier: "custom")
        regexConfig.regex = NSRegularExpression.forcePattern("pattern")
        regexConfig.matchKinds = Set([SyntaxKind.Comment])
        var customRuleConfiguration = CustomRulesConfiguration()
        customRuleConfiguration.customRuleConfigurations = [regexConfig]
        var customRules = CustomRules()
        customRules.configuration = customRuleConfiguration
        let file = File(contents: "// My file with\n// a pattern")
        XCTAssertEqual(customRules.validateFile(file),
            [StyleViolation(ruleDescription: regexConfig.description,
                severity: .Warning,
                location: Location(file: nil, line: 2, character: 6),
                reason: regexConfig.message)])
    }
}
