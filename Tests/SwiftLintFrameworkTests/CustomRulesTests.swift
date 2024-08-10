import SourceKittenFramework
@testable import SwiftLintCore
import XCTest

// swiftlint:disable file_length
// swiftlint:disable:next type_body_length
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

    func testSpecificCustomRuleSuperfluousDisableCommand() throws {
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
        XCTAssertEqual(violations.first?.ruleIdentifier, SuperfluousDisableCommandRule.description.identifier)
        XCTAssertEqual(violations.first?.didNotTrigger(for: customRuleIdentifier), true)
    }

    func testCustomRulesSuperfluousDisableCommand() throws {
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
        XCTAssertEqual(violations.first?.ruleIdentifier, SuperfluousDisableCommandRule.description.identifier)
        XCTAssertEqual(violations.first?.didNotTrigger(for: "custom_rules"), true)
    }

    func testSpecificAndCustomRulesSuperfluousDisableCommand() throws {
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
        let (firstViolation, secondViolation) = (violations[0], violations[1])
        XCTAssertEqual(firstViolation.ruleIdentifier, SuperfluousDisableCommandRule.description.identifier)
        XCTAssertTrue(firstViolation.didNotTrigger(for: "custom_rules"))
        XCTAssertEqual(secondViolation.ruleIdentifier, SuperfluousDisableCommandRule.description.identifier)
        XCTAssertTrue(secondViolation.didNotTrigger(for: "\(customRuleIdentifier)"))
    }

    func testSuperfluousDisableCommandAndViolationWithCustomRules() throws {
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
        let (firstViolation, secondViolation) = (violations[0], violations[1])
        XCTAssertEqual(firstViolation.ruleIdentifier, customRuleIdentifier)
        XCTAssertEqual(secondViolation.ruleIdentifier, SuperfluousDisableCommandRule.description.identifier)
        XCTAssertTrue(secondViolation.didNotTrigger(for: customRuleIdentifier))
    }

    func testDisablingCustomRules() throws {
        let customRules: [String: Any] = [
            "forbidden": [
                "regex": "FORBIDDEN",
            ],
        ]

        let example = Example("""
                              // swiftlint:disable:next custom_rules
                              let FORBIDDEN = 1
                              """)

        let violations = try violations(forExample: example, customRules: customRules)
        XCTAssertTrue(violations.isEmpty)
    }

    func testSuperfluousCommandWorksForCustomRules() throws {
        let customRules = getForbiddenCustomRules()
        let example = Example("""
                              // swiftlint:disable:next custom_rules
                              let ALLOWED = 2
                              """)

        let violations = try violations(forExample: example, customRules: customRules)
        XCTAssertEqual(violations.count, 1)
    }

    func testSuperfluousCommandWorksForSpecificCustomRules() throws {
        let customRules = getForbiddenCustomRules()
        let example = Example("""
                              // swiftlint:disable:next forbidden forbidden2
                              let ALLOWED = 2
                              """)

        let violations = try self.violations(forExample: example, customRules: customRules)
        XCTAssertEqual(violations.count, 2)
    }

    func testSuperfluousCommandWorksForSpecificCustomRulesWhenOneCustomRuleIsViolated() throws {
        let customRules = getForbiddenCustomRules()
        let example = Example("""
                              // swiftlint:disable:next forbidden forbidden2
                              let FORBIDDEN = 1
                              """)

        let violations = try self.violations(forExample: example, customRules: customRules)
        XCTAssertEqual(violations.count, 1)
    }

    func testSuperfluousCommandWorksForSpecificAndGeneralCustomRulesWhenOneCustomRuleIsViolated() throws {
        let customRules = getForbiddenCustomRules()
        let example = Example("""
                              // swiftlint:disable:next forbidden forbidden2 custom_rules
                              let FORBIDDEN = 1
                              """)

        let violations = try self.violations(forExample: example, customRules: customRules)
        XCTAssertEqual(violations.count, 1)
    }

    func testSuperfluousDisableCommandWithCustomRules() throws {
        let customRuleIdentifier = "custom1"
        let customRules: [String: Any] = [
            customRuleIdentifier: [
                "regex": "pattern",
                "match_kinds": "comment",
            ],
        ]

        let example = Example("// swiftlint:disable \(customRuleIdentifier)\n")
        let violations = try violations(forExample: example, customRules: customRules)

        guard let violation = violations.first else {
            XCTFail("No violations")
            return
        }
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violation.ruleIdentifier, SuperfluousDisableCommandRule.description.identifier)
        XCTAssertTrue(violation.didNotTrigger(for: customRuleIdentifier))
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
        let (firstViolation, secondViolation, thirdViolation) = (violations[0], violations[1], violations[2])
        XCTAssertEqual(firstViolation.ruleIdentifier, "custom2")
        XCTAssertEqual(secondViolation.ruleIdentifier, SuperfluousDisableCommandRule.description.identifier)
        XCTAssertTrue(secondViolation.didNotTrigger(for: "custom1"))
        XCTAssertEqual(thirdViolation.ruleIdentifier, SuperfluousDisableCommandRule.description.identifier)
        XCTAssertTrue(thirdViolation.didNotTrigger(for: "custom3"))
    }

    func testSuperfluousDisableCommandDoesNotViolate() throws {
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

    func testDisableAll() throws {
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

    func testDisableAllAndASpecificCustomRule() throws {
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

    func testRegionsForCustomRules() {
        let file = SwiftLintFile(contents: "// swiftlint:disable custom_rules\n")
        XCTAssertFalse(file.regions().first?.isRuleEnabled(CustomRules()) ?? true)

        let config: [String: Any] = [
            "regex": "pattern",
        ]

        let regexConfig = configuration(withIdentifier: "custom", configurationDict: config)
        let customRules = customRules(withConfigurations: [regexConfig])

        let file2 = SwiftLintFile(contents: "// swiftlint:disable custom\n")
        XCTAssertFalse(file2.regions().first?.isRuleEnabled(customRules) ?? true)

        let file3 = SwiftLintFile(contents: "// swiftlint:disable all\n")
        XCTAssertFalse(file3.regions().first?.isRuleEnabled(customRules) ?? true)
    }

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

    private func getForbiddenCustomRules() -> [String: Any] {
        [
            "forbidden": [
                "regex": "FORBIDDEN",
            ],
            "forbidden2": [
                "regex": "FORBIDDEN2",
            ],
        ]
    }

    private func getTestTextFile() -> SwiftLintFile {
        SwiftLintFile(path: "\(testResourcesPath)/test.txt")!
    }

    private func violations(forExample example: Example, customRules: [String: Any]) throws -> [StyleViolation] {
        let configDict: [String: Any] = [
            "only_rules": ["custom_rules", "superfluous_disable_command"],
            "custom_rules": customRules,
        ]
        let configuration = try SwiftLintCore.Configuration(dict: configDict)
        return SwiftLintTestHelpers.violations(
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
    func didNotTrigger(for ruleIdentifier: String) -> Bool {
        reason.contains("SwiftLint rule '\(ruleIdentifier)' did not trigger a violation")
    }
}
