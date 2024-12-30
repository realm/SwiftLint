import SourceKittenFramework
@testable import SwiftLintCore
@testable import SwiftLintFramework
import TestHelpers
import XCTest

// swiftlint:disable file_length
// swiftlint:disable:next type_body_length
final class CustomRulesTests: SwiftLintTestCase {
    private typealias Configuration = RegexConfiguration<CustomRules>

    private var testFile: SwiftLintFile { SwiftLintFile(path: "\(TestResources.path())/test.txt")! }

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
        checkError(Issue.invalidConfiguration(ruleID: CustomRules.identifier)) {
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

        let identifier = customRulesConfig.customRuleConfigurations.first?.identifier
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
                "match_kinds": "comment",
            ],
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
        let violations = customRules.validate(file: testFile)
        XCTAssertEqual(violations.count, 1)
    }

    func testCustomRulesIncludedExcludesFile() {
        var (regexConfig, customRules) = getCustomRules(["included": "\\.yml$"])

        var customRuleConfiguration = CustomRulesConfiguration()
        customRuleConfiguration.customRuleConfigurations = [regexConfig]
        customRules.configuration = customRuleConfiguration

        let violations = customRules.validate(file: testFile)
        XCTAssertTrue(violations.isEmpty)
    }

    func testCustomRulesExcludedExcludesFile() {
        var (regexConfig, customRules) = getCustomRules(["excluded": "\\.txt$"])

        var customRuleConfiguration = CustomRulesConfiguration()
        customRuleConfiguration.customRuleConfigurations = [regexConfig]
        customRules.configuration = customRuleConfiguration

        let violations = customRules.validate(file: testFile)
        XCTAssertTrue(violations.isEmpty)
    }

    func testCustomRulesExcludedArrayExcludesFile() {
        var (regexConfig, customRules) = getCustomRules(["excluded": ["\\.pdf$", "\\.txt$"]])

        var customRuleConfiguration = CustomRulesConfiguration()
        customRuleConfiguration.customRuleConfigurations = [regexConfig]
        customRules.configuration = customRuleConfiguration

        let violations = customRules.validate(file: testFile)
        XCTAssertTrue(violations.isEmpty)
    }

    func testCustomRulesCaptureGroup() {
        let (_, customRules) = getCustomRules([
            "regex": #"\ba\s+(\w+)"#,
            "capture_group": 1,
        ])
        let violations = customRules.validate(file: testFile)
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations[0].location.line, 2)
        XCTAssertEqual(violations[0].location.character, 6)
    }

    // MARK: - superfluous_disable_command support

    func testCustomRulesTriggersSuperfluousDisableCommand() throws {
        let customRuleIdentifier = "forbidden"
        let customRules: [String: Any] = [
            customRuleIdentifier: [
                "regex": "FORBIDDEN",
            ],
        ]
        let example = Example("""
                              // swiftlint:disable:next custom_rules
                              let ALLOWED = 2
                              """)

        let violations = try violations(forExample: example, customRules: customRules)
        XCTAssertEqual(violations.count, 1)
        XCTAssertTrue(violations[0].isSuperfluousDisableCommandViolation(for: "custom_rules"))
    }

    func testSpecificCustomRuleTriggersSuperfluousDisableCommand() throws {
        let customRuleIdentifier = "forbidden"
        let customRules: [String: Any] = [
            customRuleIdentifier: [
                "regex": "FORBIDDEN",
            ],
        ]

        let example = Example("""
                              // swiftlint:disable:next \(customRuleIdentifier)
                              let ALLOWED = 2
                              """)

        let violations = try violations(forExample: example, customRules: customRules)
        XCTAssertEqual(violations.count, 1)
        XCTAssertTrue(violations[0].isSuperfluousDisableCommandViolation(for: customRuleIdentifier))
    }

    func testSpecificAndCustomRulesTriggersSuperfluousDisableCommand() throws {
        let customRuleIdentifier = "forbidden"
        let customRules: [String: Any] = [
            customRuleIdentifier: [
                "regex": "FORBIDDEN",
            ],
        ]

        let example = Example("""
                              // swiftlint:disable:next custom_rules \(customRuleIdentifier)
                              let ALLOWED = 2
                              """)

        let violations = try violations(forExample: example, customRules: customRules)

        XCTAssertEqual(violations.count, 2)
        XCTAssertTrue(violations[0].isSuperfluousDisableCommandViolation(for: "custom_rules"))
        XCTAssertTrue(violations[1].isSuperfluousDisableCommandViolation(for: "\(customRuleIdentifier)"))
    }

    func testCustomRulesViolationAndViolationOfSuperfluousDisableCommand() throws {
        let customRuleIdentifier = "forbidden"
        let customRules: [String: Any] = [
            customRuleIdentifier: [
                "regex": "FORBIDDEN",
            ],
        ]

        let example = Example("""
                              let FORBIDDEN = 1
                              // swiftlint:disable:next \(customRuleIdentifier)
                              let ALLOWED = 2
                              """)

        let violations = try violations(forExample: example, customRules: customRules)

        XCTAssertEqual(violations.count, 2)
        XCTAssertEqual(violations[0].ruleIdentifier, customRuleIdentifier)
        XCTAssertTrue(violations[1].isSuperfluousDisableCommandViolation(for: customRuleIdentifier))
    }

    func testDisablingCustomRulesDoesNotTriggerSuperfluousDisableCommand() throws {
        let customRules: [String: Any] = [
            "forbidden": [
                "regex": "FORBIDDEN",
            ],
        ]

        let example = Example("""
                              // swiftlint:disable:next custom_rules
                              let FORBIDDEN = 1
                              """)

        XCTAssertTrue(try violations(forExample: example, customRules: customRules).isEmpty)
    }

    func testMultipleSpecificCustomRulesTriggersSuperfluousDisableCommand() throws {
        let customRules = [
            "forbidden": [
                "regex": "FORBIDDEN",
            ],
            "forbidden2": [
                "regex": "FORBIDDEN2",
            ],
        ]
        let example = Example("""
                              // swiftlint:disable:next forbidden forbidden2
                              let ALLOWED = 2
                              """)

        let violations = try self.violations(forExample: example, customRules: customRules)
        XCTAssertEqual(violations.count, 2)
        XCTAssertTrue(violations[0].isSuperfluousDisableCommandViolation(for: "forbidden"))
        XCTAssertTrue(violations[1].isSuperfluousDisableCommandViolation(for: "forbidden2"))
    }

    func testUnviolatedSpecificCustomRulesTriggersSuperfluousDisableCommand() throws {
        let customRules = [
            "forbidden": [
                "regex": "FORBIDDEN",
            ],
            "forbidden2": [
                "regex": "FORBIDDEN2",
            ],
        ]
        let example = Example("""
                              // swiftlint:disable:next forbidden forbidden2
                              let FORBIDDEN = 1
                              """)

        let violations = try self.violations(forExample: example, customRules: customRules)
        XCTAssertEqual(violations.count, 1)
        XCTAssertTrue(violations[0].isSuperfluousDisableCommandViolation(for: "forbidden2"))
    }

    func testViolatedSpecificAndGeneralCustomRulesTriggersSuperfluousDisableCommand() throws {
        let customRules = [
            "forbidden": [
                "regex": "FORBIDDEN",
            ],
            "forbidden2": [
                "regex": "FORBIDDEN2",
            ],
        ]
        let example = Example("""
                              // swiftlint:disable:next forbidden forbidden2 custom_rules
                              let FORBIDDEN = 1
                              """)

        let violations = try self.violations(forExample: example, customRules: customRules)
        XCTAssertEqual(violations.count, 1)
        XCTAssertTrue(violations[0].isSuperfluousDisableCommandViolation(for: "forbidden2"))
    }

    func testSuperfluousDisableCommandWithMultipleCustomRules() throws {
        let customRules: [String: Any] = [
            "custom1": [
                "regex": "pattern",
                "match_kinds": "comment",
            ],
            "custom2": [
                "regex": "10",
                "match_kinds": "number",
            ],
            "custom3": [
                "regex": "100",
                "match_kinds": "number",
            ],
        ]

        let example = Example(
             """
             // swiftlint:disable custom1 custom3
             return 10
             """
        )

        let violations = try violations(forExample: example, customRules: customRules)

        XCTAssertEqual(violations.count, 3)
        XCTAssertEqual(violations[0].ruleIdentifier, "custom2")
        XCTAssertTrue(violations[1].isSuperfluousDisableCommandViolation(for: "custom1"))
        XCTAssertTrue(violations[2].isSuperfluousDisableCommandViolation(for: "custom3"))
    }

    func testViolatedCustomRuleDoesNotTriggerSuperfluousDisableCommand() throws {
        let customRules: [String: Any] = [
            "dont_print": [
                "regex": "print\\("
            ],
        ]
        let example = Example("""
                               // swiftlint:disable:next dont_print
                               print("Hello, world")
                               """)
        XCTAssertTrue(try violations(forExample: example, customRules: customRules).isEmpty)
    }

    func testDisableAllDoesNotTriggerSuperfluousDisableCommand() throws {
        let customRules: [String: Any] = [
            "dont_print": [
                "regex": "print\\("
            ],
        ]
        let example = Example("""
                               // swiftlint:disable:next all
                               print("Hello, world")
                               """)
        XCTAssertTrue(try violations(forExample: example, customRules: customRules).isEmpty)
    }

    func testDisableAllAndDisableSpecificCustomRuleDoesNotTriggerSuperfluousDisableCommand() throws {
        let customRules: [String: Any] = [
            "dont_print": [
                "regex": "print\\("
            ],
        ]
        let example = Example("""
                               // swiftlint:disable:next all dont_print
                               print("Hello, world")
                               """)
        XCTAssertTrue(try violations(forExample: example, customRules: customRules).isEmpty)
    }

    func testNestedCustomRuleDisablesDoNotTriggerSuperfluousDisableCommand() throws {
        let customRules: [String: Any] = [
            "rule1": [
                "regex": "pattern1"
            ],
            "rule2": [
                "regex": "pattern2"
            ],
        ]
        let example = Example("""
                               // swiftlint:disable rule1
                               // swiftlint:disable rule2
                               let pattern2 = ""
                               // swiftlint:enable rule2
                               let pattern1 = ""
                               // swiftlint:enable rule1
                               """)
        XCTAssertTrue(try violations(forExample: example, customRules: customRules).isEmpty)
    }

    func testNestedAndOverlappingCustomRuleDisables() throws {
        let customRules: [String: Any] = [
            "rule1": [
                "regex": "pattern1"
            ],
            "rule2": [
                "regex": "pattern2"
            ],
            "rule3": [
                "regex": "pattern3"
            ],
        ]
        let example = Example("""
                              // swiftlint:disable rule1
                              // swiftlint:disable rule2
                              // swiftlint:disable rule3
                              let pattern2 = ""
                              // swiftlint:enable rule2
                              // swiftlint:enable rule3
                              let pattern1 = ""
                              // swiftlint:enable rule1
                              """)
        let violations = try violations(forExample: example, customRules: customRules)

        XCTAssertEqual(violations.count, 1)
        XCTAssertTrue(violations[0].isSuperfluousDisableCommandViolation(for: "rule3"))
    }

    func testSuperfluousDisableRuleOrder() throws {
        let customRules: [String: Any] = [
            "rule1": [
                "regex": "pattern1"
            ],
            "rule2": [
                "regex": "pattern2"
            ],
            "rule3": [
                "regex": "pattern3"
            ],
        ]
        let example = Example("""
                              // swiftlint:disable rule1
                              // swiftlint:disable rule2 rule3
                              // swiftlint:enable rule3 rule2
                              // swiftlint:disable rule2
                              // swiftlint:enable rule1
                              // swiftlint:enable rule2
                              """)
        let violations = try violations(forExample: example, customRules: customRules)

        XCTAssertEqual(violations.count, 4)
        XCTAssertTrue(violations[0].isSuperfluousDisableCommandViolation(for: "rule1"))
        XCTAssertTrue(violations[1].isSuperfluousDisableCommandViolation(for: "rule2"))
        XCTAssertTrue(violations[2].isSuperfluousDisableCommandViolation(for: "rule3"))
        XCTAssertTrue(violations[3].isSuperfluousDisableCommandViolation(for: "rule2"))
    }

    // MARK: - Private

    private func getCustomRules(_ extraConfig: [String: Any] = [:]) -> (Configuration, CustomRules) {
        var config: [String: Any] = [
            "regex": "pattern",
            "match_kinds": "comment",
        ]
        extraConfig.forEach { config[$0] = $1 }

        let regexConfig = configuration(withIdentifier: "custom", configurationDict: config)
        let customRules = customRules(withConfigurations: [regexConfig])
        return (regexConfig, customRules)
    }

    private func getCustomRulesWithTwoRules() -> ((Configuration, Configuration), CustomRules) {
        let config1 = [
            "regex": "pattern",
            "match_kinds": "comment",
        ]

        let regexConfig1 = configuration(withIdentifier: "custom1", configurationDict: config1)

        let config2 = [
            "regex": "something",
            "match_kinds": "comment",
        ]

        let regexConfig2 = configuration(withIdentifier: "custom2", configurationDict: config2)

        let customRules = customRules(withConfigurations: [regexConfig1, regexConfig2])
        return ((regexConfig1, regexConfig2), customRules)
    }

    private func violations(forExample example: Example, customRules: [String: Any]) throws -> [StyleViolation] {
        let configDict: [String: Any] = [
            "only_rules": ["custom_rules", "superfluous_disable_command"],
            "custom_rules": customRules,
        ]
        let configuration = try SwiftLintFramework.Configuration(dict: configDict)
        return TestHelpers.violations(
            example.skipWrappingInCommentTest(),
            config: configuration
        )
    }

    private func configuration(withIdentifier identifier: String, configurationDict: [String: Any]) -> Configuration {
        var regexConfig = Configuration(identifier: identifier)
        do {
            try regexConfig.apply(configuration: configurationDict)
        } catch {
            XCTFail("Failed regex config")
        }
        return regexConfig
    }

    private func customRules(withConfigurations configurations: [Configuration]) -> CustomRules {
        var customRuleConfiguration = CustomRulesConfiguration()
        customRuleConfiguration.customRuleConfigurations = configurations
        var customRules = CustomRules()
        customRules.configuration = customRuleConfiguration
        return customRules
    }
}

private extension StyleViolation {
    func isSuperfluousDisableCommandViolation(for ruleIdentifier: String) -> Bool {
        self.ruleIdentifier == SuperfluousDisableCommandRule.identifier &&
            reason.contains("SwiftLint rule '\(ruleIdentifier)' did not trigger a violation")
    }
}
