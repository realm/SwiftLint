//
//  CustomRulesTests.swift
//  SwiftLint
//
//  Created by Scott Hoyt on 1/21/16.
//  Copyright © 2016 Realm. All rights reserved.
//

import XCTest
import SwiftLintFramework
import SourceKittenFramework

class CustomRulesTests: XCTestCase {

    // protocol XCTestCaseProvider
    lazy var allTests: [(String, () throws -> Void)] = [
        ("testCustomRuleConfigSetsCorrectly", self.testCustomRuleConfigSetsCorrectly),
        ("testCustomRuleConfigThrows", self.testCustomRuleConfigThrows),
        ("testCustomRules", self.testCustomRules),
    ]

    func testCustomRuleConfigSetsCorrectly() {
        let configDict = ["my_custom_rule": ["name": "MyCustomRule",
            "message": "Message",
            "regex": "regex",
            "match_kinds": "comment",
            "severity": "error"]]
        var comp = RegexConfig(identifier: "my_custom_rule")
        comp.name = "MyCustomRule"
        comp.message = "Message"
        comp.regex = NSRegularExpression.forcePattern("regex")
        comp.severityConfig = SeverityConfig(.Error)
        comp.matchKinds = Set([SyntaxKind.Comment])
        var compRules = CustomRulesConfig()
        compRules.customRuleConfigs = [comp]
        do {
            var config = CustomRulesConfig()
            try config.setConfig(configDict)
            XCTAssertEqual(config, compRules)
        } catch {
            XCTFail("Did not configure correctly")
        }
    }

    func testCustomRuleConfigThrows() {
        let config = 17
        var customRulesConfig = CustomRulesConfig()
        checkError(ConfigurationError.UnknownConfiguration) {
            try customRulesConfig.setConfig(config)
        }
    }

    func testCustomRules() {
        var regexConfig = RegexConfig(identifier: "custom")
        regexConfig.regex = NSRegularExpression.forcePattern("pattern")
        regexConfig.matchKinds = Set([SyntaxKind.Comment])
        var customRuleConfig = CustomRulesConfig()
        customRuleConfig.customRuleConfigs = [regexConfig]
        var customRules = CustomRules()
        customRules.config = customRuleConfig
        let file = File(contents: "// My file with\n// a pattern")
        XCTAssertEqual(customRules.validateFile(file),
            [StyleViolation(ruleDescription: regexConfig.description,
                severity: .Warning,
                location: Location(file: nil, line: 2, character: 6),
                reason: regexConfig.message)])
    }
}
