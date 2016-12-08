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
        comp.regex = .forcePattern("regex")
        comp.severityConfiguration = SeverityConfiguration(.error)
        comp.matchKinds = Set([SyntaxKind.comment])
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
        checkError(ConfigurationError.unknownConfiguration) {
            try customRulesConfig.applyConfiguration(config)
        }
    }

    func testCustomRules() {
        let (regexConfig, customRules) = getCustomRules()

        let file = File(contents: "// My file with\n// a pattern")
        XCTAssertEqual(customRules.validateFile(file),
                       [StyleViolation(ruleDescription: regexConfig.description,
                        severity: .warning,
                        location: Location(file: nil, line: 2, character: 6),
                        reason: regexConfig.message)])
    }

    func testLocalDisableCustomRule() {
        let (_, customRules) = getCustomRules()
        let file = File(contents: "//swiftlint:disable custom \n// file with a pattern")
        XCTAssertEqual(customRules.validateFile(file), [])
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

    func testBasicCorrectableCustomRule() {
        var (regexConfig, customRules) = getCustomRules(["template": "replaced"])

        var customRuleConfiguration = CustomRulesConfiguration()
        customRuleConfiguration.customRuleConfigurations = [regexConfig]
        customRules.configuration = customRuleConfiguration

        let file = File(contents: "// My file with\n// a pattern")
        XCTAssertEqual(customRules.validateFile(file),
                       [StyleViolation(ruleDescription: regexConfig.description,
                                       severity: .warning,
                                       location: Location(file: nil, line: 2, character: 6),
                                       reason: regexConfig.message)])

        guard let path = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(NSUUID().uuidString + ".swift")?.path else {
                XCTFail("couldn't generate temporary path for custom rule correction")
                return
        }
        do {
            try file.contents.write(toFile: path, atomically: true, encoding: .utf8)
        } catch {
            XCTFail("couldn't write to file for custom rule correction with error: \(error)")
            return
        }
        guard let correctedFile = File(path: path) else {
            XCTFail("couldn't read file at path '\(path)' for custom rule correction")
            return
        }
        let corrections = customRules.correctFile(correctedFile)
        XCTAssertEqual(corrections.count, 1)
    }

    //swiftlint:disable:next function_body_length
    func testDictionaryColonCorrectableCustomRule() {
        let pattern =
            "(\\w|[\"]?)" +       // Capture an identifier
                "(?:" +         // start group
                "\\s+" +        // followed by whitespace
                ":" +           // to the left of a colon
                "\\s*" +        // followed by any amount of whitespace.
                "|" +           // or
                ":" +           // immediately followed by a colon
                "(?:\\s{0}|\\s{2,})" +  // followed by right spacing regex
                ")" +           // end group
                "(" +           // Capture a type identifier
                "[\\[|\\(]*" +  // which may begin with a series of nested parenthesis or brackets
        "\\S)"          // lazily to the first non-whitespace character.

        var (regexConfig, customRules) = getCustomRules(["regex": pattern,
                                                         "template": "$1: $2",
                                                         "match_kinds": ""])

        var customRuleConfiguration = CustomRulesConfiguration()
        customRuleConfiguration.customRuleConfigurations = [regexConfig]
        customRules.configuration = customRuleConfiguration

        let file = File(contents:
            "let abc: [Void : Void]\n" +
            "let abc: [Void :Void]\n" +
            "let abc: ([Void: Void], [Void :[Void: Void]])\n" +
            "let abc: ([Void: Void], [Void:[Void : Void]])\n" +
            "let abc: ([Void : Void], [Void : [Void : Void]])\n" +
            "let abc: [String: String] = [\"key\" : \"value\"]" +
            "let abc: [String: String] = [\"key\" :\"value\"]")
        XCTAssertEqual(customRules.validateFile(file).count, 10)

        guard let path = NSURL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(NSUUID().uuidString + ".swift")?.path else {
                XCTFail("couldn't generate temporary path for custom rule correction")
                return
        }
        do {
            try file.contents.write(toFile: path, atomically: true, encoding: .utf8)
        } catch {
            XCTFail("couldn't write to file for custom rule correction with error: \(error)")
            return
        }
        guard let correctedFile = File(path: path) else {
            XCTFail("couldn't read file at path '\(path)' for custom rule correction")
            return
        }
        let corrections = customRules.correctFile(correctedFile)
        XCTAssertEqual(corrections.count, 10)
    }

    func getCustomRules(_ extraConfig: [String:String] = [:]) -> (RegexConfiguration, CustomRules) {
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
            let path: String = "Tests/SwiftLintFrameworkTests/Resources/test.txt"
                .absolutePathRepresentation()
            return File(path: path)!
        #else
            let testBundle = Bundle(for: type(of: self))
            let path: String? = testBundle.path(forResource: "test", ofType: "txt")
            if path != nil {
                return File(path: path!)!
            }
        #endif
        fatalError("Could not load test.txt")
    }
}
