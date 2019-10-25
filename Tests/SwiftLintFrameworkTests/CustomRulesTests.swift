import SourceKittenFramework
@testable import SwiftLintFramework
import XCTest

class CustomRulesTests: XCTestCase {
    func testCustomRuleConfigurationSetsCorrectly() {
        let configDict = [
            "my_custom_rule": [
                "name": "MyCustomRule",
                "message": "Message",
                "regex": "regex",
                "match_kinds": "comment",
                "severity": "error"
            ]
        ]
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

    func testCustomRulesMultiLineRegexFile() {
        var comp = RegexConfiguration(identifier: "my_multiline_rule")
        comp.name = "MyMultilineRule"
        comp.message = "Message"
        comp.regex = regex(#"""
    (?!.*\b(set|get|weak)\b.*$)(?:^\s*\bvar\b\s+\b(\w*controller\w*)\b\s*:\s*.*\?.*$)
    """#)

        comp.severityConfiguration = SeverityConfiguration(.error)
        comp.matchKinds = SyntaxKind.allKinds

        var compRules = CustomRulesConfiguration()
        compRules.customRuleConfigurations = [comp]

        var rule = CustomRules()
        rule.configuration = compRules

        let testFiles = getTestSwiftFiles()
        XCTAssertEqual(testFiles.count, 2)

        let violations0 = rule.validate(file: testFiles[0])
        XCTAssertEqual(violations0.count, 1)
        XCTAssertEqual(violations0.first?.location.line, 23)

        let violations1 = rule.validate(file: testFiles[1])
        XCTAssertEqual(violations1.count, 1)
        XCTAssertEqual(violations1.first?.location.line, 32)
    }

    func testCustomRulesMultiLineRegexFileFromConfiguration() {
        let config = Configuration(path: "config.yml",
                                   rootPath: "\(testResourcesPath)/MultiLineRegex",
            optional: false,
            quiet: false)

        XCTAssertNotNil(config)
        XCTAssertEqual(config.rules.count, 1)

        let swiftFiles = config
            .lintableFiles(inPath: "\(testResourcesPath)/MultiLineRegex", forceExclude: false)
            .sorted { $0.path! > $1.path! }
        XCTAssertEqual(swiftFiles.count, 2)

        let testFiles = getTestSwiftFiles().sorted { $0.path! > $1.path! }
        XCTAssertEqual(testFiles.count, 2)
        XCTAssertEqual(swiftFiles[0].path, testFiles[0].path)
        XCTAssertEqual(swiftFiles[1].path, testFiles[1].path)

        let storage = RuleStorage()
        let violations = swiftFiles.parallelFlatMap {
            Linter(file: $0, configuration: config)
                .collect(into: storage)
                .styleViolations(using: storage)
        }
        XCTAssertEqual(violations.count, 2)

        let violations0 = violations.filter {
            URL(string: $0.location.file!)!.lastPathComponent == "MyPresenter.swift"
        }
        XCTAssertEqual(violations0.count, 1)
        XCTAssertEqual(violations0.first?.location.line, 23)

        let violations1 = violations.filter {
            URL(string: $0.location.file!)!.lastPathComponent == "MyPatientsPresenter.swift"
        }
        XCTAssertEqual(violations1.count, 1)
        XCTAssertEqual(violations1.first?.location.line, 32)
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
        return File(path: "\(testResourcesPath)/test.txt")!
    }

    private func getTestSwiftFiles() -> [File] {
        return [File(path: "\(testResourcesPath)/MultiLineRegex/MyPresenter.swift")!,
                File(path: "\(testResourcesPath)/MultiLineRegex/MyPatientsPresenter.swift")!]
    }
}
