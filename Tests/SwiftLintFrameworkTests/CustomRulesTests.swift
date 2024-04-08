import SourceKittenFramework
@testable import SwiftLintCore
import XCTest

final class CustomRulesTests: SwiftLintTestCase {
    typealias Configuration = RegexConfiguration<CustomRules>
    func testCustomRuleConfigurationSetsCorrectlyWithMatchKinds() {
        let configDict = [
            "my_custom_rule": [
                "name": "MyCustomRule",
                "message": "Message",
                "regex": "regex",
                "match_kinds": "comment",
                "severity": "error",
            ],
        ]
        var comp = Configuration(identifier: "my_custom_rule")
        comp.name = "MyCustomRule"
        comp.message = "Message"
        comp.regex = "regex"
        comp.severityConfiguration = SeverityConfiguration(.error)
        comp.excludedMatchKinds = SyntaxKind.allKinds.subtracting([.comment])
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

    func testCustomRuleConfigurationSetsCorrectlyWithExcludedMatchKinds() {
        let configDict = [
            "my_custom_rule": [
                "name": "MyCustomRule",
                "message": "Message",
                "regex": "regex",
                "excluded_match_kinds": "comment",
                "severity": "error",
            ],
        ]
        var comp = Configuration(identifier: "my_custom_rule")
        comp.name = "MyCustomRule"
        comp.message = "Message"
        comp.regex = "regex"
        comp.severityConfiguration = SeverityConfiguration(.error)
        comp.excludedMatchKinds = Set<SyntaxKind>([.comment])
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
        checkError(Issue.invalidConfiguration(ruleID: CustomRules.description.identifier)) {
            try customRulesConfig.apply(configuration: config)
        }
    }

    func testCustomRuleConfigurationMatchKindAmbiguity() {
        let configDict = [
            "name": "MyCustomRule",
            "message": "Message",
            "regex": "regex",
            "match_kinds": "comment",
            "excluded_match_kinds": "argument",
            "severity": "error",
        ]

        var configuration = Configuration(identifier: "my_custom_rule")
        let expectedError = Issue.genericWarning(
            "The configuration keys 'match_kinds' and 'excluded_match_kinds' cannot appear at the same time."
        )
        checkError(expectedError) {
            try configuration.apply(configuration: configDict)
        }
    }

    func testCustomRuleConfigurationIgnoreInvalidRules() throws {
        let configDict = [
            "my_custom_rule": [
                "name": "MyCustomRule",
                "message": "Message",
                "regex": "regex",
                "match_kinds": "comment",
                "severity": "error",
            ],
            "invalid_rule": ["name": "InvalidRule"], // missing `regex`
        ]
        var customRulesConfig = CustomRulesConfiguration()
        try customRulesConfig.apply(configuration: configDict)

        XCTAssertEqual(customRulesConfig.customRuleConfigurations.count, 1)

        let identifier = customRulesConfig.customRuleConfigurations.first?.description.identifier
        XCTAssertEqual(identifier, "my_custom_rule")
    }

    func testCustomRules() {
        let (regexConfig, customRules) = getCustomRules()

        let file = SwiftLintFile(contents: "// My file with\n// a pattern")
        XCTAssertEqual(
            customRules.validate(file: file),
            [
                StyleViolation(
                    ruleDescription: regexConfig.description,
                    severity: .warning,
                    location: Location(file: nil, line: 2, character: 6),
                    reason: regexConfig.message
                ),
            ]
        )
    }

    func testLocalDisableCustomRule() throws {
        let customRules: [String: Any] = [
            "custom": [
                "regex": "pattern",
                "match_kinds": "comment"
            ]
        ]
        let example = Example("//swiftlint:disable custom \n// file with a pattern")
        let violations = try violations(forExample: example, customRules: customRules)

        XCTAssertTrue(violations.isEmpty)
    }

    func testLocalDisableCustomRuleWithMultipleRules() {
        let (configs, customRules) = getCustomRulesWithTwoRules()
        let file = SwiftLintFile(contents: "//swiftlint:disable \(configs.1.identifier) \n// file with a pattern")
        XCTAssertEqual(
            customRules.validate(file: file),
            [
                StyleViolation(
                    ruleDescription: configs.0.description,
                    severity: .warning,
                    location: Location(file: nil, line: 2, character: 16),
                    reason: configs.0.message
                ),
            ]
        )
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

    func testCustomRulesExcludedArrayExcludesFile() {
        var (regexConfig, customRules) = getCustomRules(["excluded": ["\\.pdf$", "\\.txt$"]])

        var customRuleConfiguration = CustomRulesConfiguration()
        customRuleConfiguration.customRuleConfigurations = [regexConfig]
        customRules.configuration = customRuleConfiguration

        let violations = customRules.validate(file: getTestTextFile())
        XCTAssertEqual(violations.count, 0)
    }

    func testCustomRulesCaptureGroup() {
        let (_, customRules) = getCustomRules([
            "regex": #"\ba\s+(\w+)"#,
            "capture_group": 1,
        ])
        let violations = customRules.validate(file: getTestTextFile())
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations[0].location.line, 2)
        XCTAssertEqual(violations[0].location.character, 6)
    }

    func testSuperfluousDisableCommandWithCustomRules() throws {
        let customRules: [String: Any] = [
            "custom1": [
                "regex": "pattern",
                "match_kinds": "comment"
            ]
        ]

        let example = Example("// swiftlint:disable custom1\n")
        let violations = try violations(forExample: example, customRules: customRules)

        XCTAssertEqual(violations.count, 1)
        XCTAssertTrue(violations.allSatisfy { $0.ruleIdentifier == "superfluous_disable_command" })
        XCTAssertTrue(violations.contains { violation in
            violation.description.contains("SwiftLint rule 'custom1' did not trigger a violation")
        })
    }

    func testSuperfluousDisableCommandWithMultipleCustomRules() throws {
        let customRules: [String: Any] = [
            "custom1": [
                "regex": "pattern",
                "match_kinds": "comment"
            ],
            "custom2": [
                "regex": "10",
                "match_kinds": "number"
            ],
            "custom3": [
                "regex": "100",
                "match_kinds": "number"
            ]
        ]

        let example = Example(
            """
            // swiftlint:disable custom1 custom3
            return 10
            """
        )

        let violations = try violations(forExample: example, customRules: customRules)

        XCTAssertEqual(violations.count, 3)
        XCTAssertEqual(violations.filter { $0.ruleIdentifier == "superfluous_disable_command" }.count, 2)
        XCTAssertEqual(violations.filter { $0.ruleIdentifier == "custom2" }.count, 1)
        XCTAssertTrue(violations.contains { violation in
            violation.description.contains("SwiftLint rule 'custom1' did not trigger a violation")
        })
        XCTAssertTrue(violations.contains { violation in
            violation.description.contains("SwiftLint rule 'custom3' did not trigger a violation")
        })
    }


    func testSuperfluousDisableCommandDoesNotViolate() throws {
        let customRules: [String: Any] = [
            "dont_print": [
                "regex": "print\\("
            ]
        ]
        let example = Example("""
                              // swiftlint:disable:next dont_print
                              print("Hello, world")
                              """)
        XCTAssertTrue(try violations(forExample: example, customRules: customRules).isEmpty)
    }

    private func getCustomRules(_ extraConfig: [String: Any] = [:]) -> (Configuration, CustomRules) {
        var config: [String: Any] = [
            "regex": "pattern",
            "match_kinds": "comment",
        ]
        extraConfig.forEach { config[$0] = $1 }

        var regexConfig = RegexConfiguration<CustomRules>(identifier: "custom")
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

    private func getCustomRulesWithTwoRules() -> ((Configuration, Configuration), CustomRules) {
        let config1 = [
            "regex": "pattern",
            "match_kinds": "comment",
        ]

        var regexConfig1 = Configuration(identifier: "custom1")
        do {
            try regexConfig1.apply(configuration: config1)
        } catch {
            XCTFail("Failed regex config")
        }

        let config2 = [
            "regex": "something",
            "match_kinds": "comment",
        ]

        var regexConfig2 = Configuration(identifier: "custom2")
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

    private func getTestTextFile() -> SwiftLintFile {
        return SwiftLintFile(path: "\(testResourcesPath)/test.txt")!
    }

    private func violations(forExample example: Example, customRules: [String: Any]) throws -> [StyleViolation] {
        let configDict: [String: Any] = [
            "only_rules": ["custom_rules", "superfluous_disable_command"],
            "custom_rules": customRules
        ]
        let configuration = try SwiftLintCore.Configuration(dict: configDict)
        return SwiftLintTestHelpers.violations(
            example.skipWrappingInCommentTest(),
            config: configuration
        )
    }
}
