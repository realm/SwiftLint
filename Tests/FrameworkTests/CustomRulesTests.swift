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

    override func invokeTest() {
        CurrentRule.$allowSourceKitRequestWithoutRule.withValue(true) {
            super.invokeTest()
        }
    }

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
        comp.executionMode = .default
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
        comp.executionMode = .default
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

    // MARK: - ExecutionMode Tests (Phase 1)

    func testRegexConfigurationParsesExecutionMode() throws {
        let configDict = [
            "regex": "pattern",
            "execution_mode": "swiftsyntax",
        ]

        var regexConfig = Configuration(identifier: "test_rule")
        try regexConfig.apply(configuration: configDict)
        XCTAssertEqual(regexConfig.executionMode, .swiftsyntax)
    }

    func testRegexConfigurationParsesSourceKitMode() throws {
        let configDict = [
            "regex": "pattern",
            "execution_mode": "sourcekit",
        ]

        var regexConfig = Configuration(identifier: "test_rule")
        try regexConfig.apply(configuration: configDict)
        XCTAssertEqual(regexConfig.executionMode, .sourcekit)
    }

    func testRegexConfigurationWithoutModeIsDefault() throws {
        let configDict = [
            "regex": "pattern",
        ]

        var regexConfig = Configuration(identifier: "test_rule")
        try regexConfig.apply(configuration: configDict)
        XCTAssertEqual(regexConfig.executionMode, .default)
    }

    func testRegexConfigurationRejectsInvalidMode() {
        let configDict = [
            "regex": "pattern",
            "execution_mode": "invalid_mode",
        ]

        var regexConfig = Configuration(identifier: "test_rule")
        checkError(Issue.invalidConfiguration(ruleID: CustomRules.identifier)) {
            try regexConfig.apply(configuration: configDict)
        }
    }

    func testCustomRulesConfigurationParsesDefaultExecutionMode() throws {
        let configDict: [String: Any] = [
            "default_execution_mode": "swiftsyntax",
            "my_rule": [
                "regex": "pattern",
            ],
        ]

        var customRulesConfig = CustomRulesConfiguration()
        try customRulesConfig.apply(configuration: configDict)
        XCTAssertEqual(customRulesConfig.defaultExecutionMode, .swiftsyntax)
        XCTAssertEqual(customRulesConfig.customRuleConfigurations.count, 1)
        XCTAssertEqual(customRulesConfig.customRuleConfigurations[0].executionMode, .default)
    }

    func testCustomRulesAppliesDefaultModeToRulesWithoutExplicitMode() throws {
        let configDict: [String: Any] = [
            "default_execution_mode": "sourcekit",
            "rule1": [
                "regex": "pattern1",
            ],
            "rule2": [
                "regex": "pattern2",
                "execution_mode": "swiftsyntax",
            ],
        ]

        var customRulesConfig = CustomRulesConfiguration()
        try customRulesConfig.apply(configuration: configDict)
        XCTAssertEqual(customRulesConfig.defaultExecutionMode, .sourcekit)
        XCTAssertEqual(customRulesConfig.customRuleConfigurations.count, 2)

        // rule1 should have default mode
        let rule1 = customRulesConfig.customRuleConfigurations.first { $0.identifier == "rule1" }
        XCTAssertEqual(rule1?.executionMode, .default)

        // rule2 should keep its explicit mode
        let rule2 = customRulesConfig.customRuleConfigurations.first { $0.identifier == "rule2" }
        XCTAssertEqual(rule2?.executionMode, .swiftsyntax)
    }

    func testCustomRulesConfigurationRejectsInvalidDefaultMode() {
        let configDict: [String: Any] = [
            "default_execution_mode": "invalid",
            "my_rule": [
                "regex": "pattern",
            ],
        ]

        var customRulesConfig = CustomRulesConfiguration()
        checkError(Issue.invalidConfiguration(ruleID: CustomRules.identifier)) {
            try customRulesConfig.apply(configuration: configDict)
        }
    }

    func testExecutionModeIncludedInCacheDescription() {
        var regexConfig = Configuration(identifier: "test_rule")
        regexConfig.regex = "pattern"
        regexConfig.executionMode = .swiftsyntax

        XCTAssertTrue(regexConfig.cacheDescription.contains("swiftsyntax"))
    }

    func testExecutionModeAffectsHash() {
        var config1 = Configuration(identifier: "test_rule")
        config1.regex = "pattern"
        config1.executionMode = .swiftsyntax

        var config2 = Configuration(identifier: "test_rule")
        config2.regex = "pattern"
        config2.executionMode = .sourcekit

        var config3 = Configuration(identifier: "test_rule")
        config3.regex = "pattern"
        config3.executionMode = .default

        // Different execution modes should produce different hashes
        XCTAssertNotEqual(config1.hashValue, config2.hashValue)
        XCTAssertNotEqual(config1.hashValue, config3.hashValue)
        XCTAssertNotEqual(config2.hashValue, config3.hashValue)
    }

    // MARK: - Phase 2 Tests: SwiftSyntax Mode Execution

    func testCustomRuleUsesSwiftSyntaxModeWhenConfigured() throws {
        // Test that a rule configured with swiftsyntax mode works correctly
        let customRules: [String: Any] = [
            "no_foo": [
                "regex": "\\bfoo\\b",
                "execution_mode": "swiftsyntax",
                "message": "Don't use foo",
            ],
        ]

        let example = Example("let foo = 42")
        let violations = try violations(forExample: example, customRules: customRules)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations[0].ruleIdentifier, "no_foo")
        XCTAssertEqual(violations[0].reason, "Don't use foo")
        XCTAssertEqual(violations[0].location.line, 1)
        XCTAssertEqual(violations[0].location.character, 5)
    }

    func testCustomRuleWithoutMatchKindsUsesSwiftSyntaxByDefault() throws {
        // When default_execution_mode is swiftsyntax, rules without match_kinds should use it
        let customRules: [String: Any] = [
            "default_execution_mode": "swiftsyntax",
            "no_bar": [
                "regex": "\\bbar\\b",
                "message": "Don't use bar",
            ],
        ]

        let example = Example("let bar = 42  // bar is not allowed")
        let violations = try violations(forExample: example, customRules: customRules)

        // Should find both occurrences of 'bar' since no match_kinds filtering
        XCTAssertEqual(violations.count, 2)
        XCTAssertEqual(violations[0].location.line, 1)
        XCTAssertEqual(violations[0].location.character, 5)
        XCTAssertEqual(violations[1].location.line, 1)
        XCTAssertEqual(violations[1].location.character, 18)
    }

    func testCustomRuleDefaultsToSwiftSyntaxWhenNoModeSpecified() throws {
        // When NO execution mode is specified (neither default nor per-rule), it should default to swiftsyntax
        let customRules: [String: Any] = [
            "no_foo": [
                "regex": "\\bfoo\\b",
                "message": "Don't use foo",
            ],
        ]

        let example = Example("let foo = 42")
        let violations = try violations(forExample: example, customRules: customRules)

        // Should work correctly with implicit swiftsyntax mode
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations[0].ruleIdentifier, "no_foo")
        XCTAssertEqual(violations[0].reason, "Don't use foo")

        // Verify the rule is effectively SourceKit-free
        let configuration = try SwiftLintFramework.Configuration(dict: [
            "only_rules": ["custom_rules"],
            "custom_rules": customRules,
        ])

        guard let customRule = configuration.rules.first(where: { $0 is CustomRules }) as? CustomRules else {
            XCTFail("Expected CustomRules in configuration")
            return
        }

        XCTAssertTrue(customRule.isEffectivelySourceKitFree,
                      "Rule should be effectively SourceKit-free when defaulting to swiftsyntax")
    }

    func testCustomRuleWithMatchKindsUsesSwiftSyntaxWhenConfigured() throws {
        // Phase 4: Rules with match_kinds in swiftsyntax mode should use SwiftSyntax bridging
        let customRules: [String: Any] = [
            "comment_foo": [
                "regex": "foo",
                "execution_mode": "swiftsyntax",
                "match_kinds": "comment",
                "message": "No foo in comments",
            ],
        ]

        let example = Example("""
            let foo = 42  // This foo should match
            let bar = 42  // This should not match
            """)
        let violations = try violations(forExample: example, customRules: customRules)

        // Should only match 'foo' in comment, not in code
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations[0].location.line, 1)
        XCTAssertEqual(violations[0].location.character, 23) // Position of 'foo' in comment
    }

    func testCustomRuleWithKindFilteringDefaultsToSwiftSyntax() throws {
        // When using kind filtering without specifying mode, it should default to swiftsyntax
        let customRules: [String: Any] = [
            "no_keywords": [
                "regex": "\\b\\w+\\b",
                "excluded_match_kinds": "keyword",
                "message": "Found non-keyword",
            ],
        ]

        let example = Example("let foo = 42")
        let violations = try violations(forExample: example, customRules: customRules)

        // Should match 'foo' and '42' but not 'let' (keyword)
        XCTAssertEqual(violations.count, 2)
        XCTAssertEqual(violations[0].location.character, 5) // 'foo'
        XCTAssertEqual(violations[1].location.character, 11) // '42'

        // Verify the rule is effectively SourceKit-free
        let configuration = try SwiftLintFramework.Configuration(dict: [
            "only_rules": ["custom_rules"],
            "custom_rules": customRules,
        ])

        guard let customRule = configuration.rules.first(where: { $0 is CustomRules }) as? CustomRules else {
            XCTFail("Expected CustomRules in configuration")
            return
        }

        XCTAssertTrue(customRule.isEffectivelySourceKitFree,
                      "Rule with kind filtering should default to swiftsyntax mode")
    }

    func testCustomRuleWithExcludedMatchKindsUsesSwiftSyntaxWithDefaultMode() throws {
        // Phase 4: Rules with excluded_match_kinds should use SwiftSyntax when default mode is swiftsyntax
        let customRules: [String: Any] = [
            "default_execution_mode": "swiftsyntax",
            "no_foo_outside_comments": [
                "regex": "foo",
                "excluded_match_kinds": "comment",
                "message": "No foo outside comments",
            ],
        ]

        let example = Example("""
            let foo = 42  // This foo in comment should not match
            let foobar = 42
            """)
        let violations = try violations(forExample: example, customRules: customRules)

        // Should match 'foo' in code but not in comment
        XCTAssertEqual(violations.count, 2)
        XCTAssertEqual(violations[0].location.line, 1)
        XCTAssertEqual(violations[0].location.character, 5) // 'foo' in variable name
        XCTAssertEqual(violations[1].location.line, 2)
        XCTAssertEqual(violations[1].location.character, 5) // 'foo' in foobar
    }

    func testSwiftSyntaxModeProducesSameResultsAsSourceKitForSimpleRules() throws {
        // Test that both modes produce identical results for rules without kind filtering
        let pattern = "\\bTODO\\b"
        let message = "TODOs should be resolved"

        let swiftSyntaxRules: [String: Any] = [
            "todo_rule": [
                "regex": pattern,
                "execution_mode": "swiftsyntax",
                "message": message,
            ],
        ]

        let sourceKitRules: [String: Any] = [
            "todo_rule": [
                "regex": pattern,
                "execution_mode": "sourcekit",
                "message": message,
            ],
        ]

        let example = Example("""
            // TODO: Fix this later
            func doSomething() {
                // Another TODO item
                print("TODO is not matched in strings")
            }
            """)

        let swiftSyntaxViolations = try violations(forExample: example, customRules: swiftSyntaxRules)
        let sourceKitViolations = try violations(forExample: example, customRules: sourceKitRules)

        // Both modes should produce identical results
        XCTAssertEqual(swiftSyntaxViolations.count, sourceKitViolations.count)
        XCTAssertEqual(swiftSyntaxViolations.count, 3) // Two in comments, one in string

        // Verify locations match
        for (ssViolation, skViolation) in zip(swiftSyntaxViolations, sourceKitViolations) {
            XCTAssertEqual(ssViolation.location.line, skViolation.location.line)
            XCTAssertEqual(ssViolation.location.character, skViolation.location.character)
            XCTAssertEqual(ssViolation.reason, skViolation.reason)
        }
    }

    func testSwiftSyntaxModeWithCaptureGroups() throws {
        // Test that capture groups work correctly in SwiftSyntax mode
        let customRules: [String: Any] = [
            "number_suffix": [
                "regex": "\\b(\\d+)_suffix\\b",
                "capture_group": 1,
                "execution_mode": "swiftsyntax",
                "message": "Number found",
            ],
        ]

        let example = Example("let value = 42_suffix + 100_suffix")
        let violations = try violations(forExample: example, customRules: customRules)

        XCTAssertEqual(violations.count, 2)
        // First capture group should highlight just the number part
        XCTAssertEqual(violations[0].location.character, 13) // Position of "42"
        XCTAssertEqual(violations[1].location.character, 25) // Position of "100"
    }

    func testSwiftSyntaxModeRespectsIncludedExcludedPaths() throws {
        // Verify that included/excluded path filtering works in SwiftSyntax mode
        var regexConfig = Configuration(identifier: "test_rule")
        regexConfig.regex = "pattern"
        regexConfig.executionMode = .swiftsyntax
        regexConfig.included = [try RegularExpression(pattern: "\\.swift$")]
        regexConfig.excluded = [try RegularExpression(pattern: "Tests")]

        XCTAssertTrue(regexConfig.shouldValidate(filePath: "/path/to/file.swift"))
        XCTAssertFalse(regexConfig.shouldValidate(filePath: "/path/to/file.m"))
        XCTAssertFalse(regexConfig.shouldValidate(filePath: "/path/to/Tests/file.swift"))
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

    // MARK: - Phase 4 Tests: SwiftSyntax Mode WITH Kind Filtering

    func testSwiftSyntaxModeWithMatchKindsProducesCorrectResults() throws {
        // Test various syntax kinds with SwiftSyntax bridging
        let customRules: [String: Any] = [
            "keyword_test": [
                "regex": "\\b\\w+\\b",
                "execution_mode": "swiftsyntax",
                "match_kinds": "keyword",
                "message": "Found keyword",
            ],
        ]

        let example = Example("""
            let value = 42
            func test() {
                return value
            }
            """)
        let violations = try violations(forExample: example, customRules: customRules)

        // Should match 'let', 'func', and 'return' keywords
        XCTAssertEqual(violations.count, 3)

        // Verify the locations correspond to keywords
        let expectedLocations = [
            (line: 1, character: 1),  // 'let'
            (line: 2, character: 1),  // 'func'
            (line: 3, character: 5),  // 'return'
        ]

        for (index, expected) in expectedLocations.enumerated() {
            XCTAssertEqual(violations[index].location.line, expected.line)
            XCTAssertEqual(violations[index].location.character, expected.character)
        }
    }

    func testSwiftSyntaxModeWithExcludedKindsFiltersCorrectly() throws {
        // Test that excluded kinds are properly filtered out
        let customRules: [String: Any] = [
            "no_identifier": [
                "regex": "\\b\\w+\\b",
                "execution_mode": "swiftsyntax",
                "excluded_match_kinds": ["identifier", "typeidentifier"],
                "message": "Found non-identifier",
            ],
        ]

        let example = Example("""
            let value: Int = 42
            """)
        let violations = try violations(forExample: example, customRules: customRules)

        // Should match 'let' (keyword) and '42' (number), but not 'value' or 'Int'
        XCTAssertEqual(violations.count, 2)
    }

    func testSwiftSyntaxModeHandlesComplexKindMatching() throws {
        // Test matching multiple specific kinds
        let customRules: [String: Any] = [
            "special_tokens": [
                "regex": "\\S+",
                "execution_mode": "swiftsyntax",
                "match_kinds": ["string", "number", "comment"],
                "message": "Found special token",
            ],
        ]

        let example = Example("""
            let name = "Alice"  // User name
            let age = 25
            """)
        let violations = try violations(forExample: example, customRules: customRules)

        // Should match "Alice" (string), 25 (number), and "// User name" (comment)
        // The regex \S+ will match non-whitespace sequences
        XCTAssertGreaterThanOrEqual(violations.count, 3)
    }

    func testSwiftSyntaxModeWorksWithCaptureGroups() throws {
        // Test that capture groups work correctly with SwiftSyntax mode
        let customRules: [String: Any] = [
            "string_content": [
                "regex": #""([^"]+)""#,
                "execution_mode": "swiftsyntax",
                "match_kinds": "string",
                "capture_group": 1,
                "message": "String content",
            ],
        ]

        let example = Example(#"let greeting = "Hello, World!""#)
        let violations = try violations(forExample: example, customRules: customRules)

        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations[0].location.character, 17) // Start of "Hello, World!" content
    }

    func testSwiftSyntaxModeRespectsSourceKitModeOverride() throws {
        // Test that explicit sourcekit mode overrides default swiftsyntax mode
        let customRules: [String: Any] = [
            "default_execution_mode": "swiftsyntax",
            "sourcekit_rule": [
                "regex": "foo",
                "execution_mode": "sourcekit",
                "match_kinds": "identifier",
                "message": "Found foo",
            ],
        ]

        let example = Example("let foo = 42")
        let violations = try violations(forExample: example, customRules: customRules)

        // Should still work correctly with explicit sourcekit mode
        XCTAssertEqual(violations.count, 1)
        XCTAssertEqual(violations[0].location.character, 5)
    }

    func testSwiftSyntaxModeHandlesEmptyBridging() throws {
        // Test graceful handling when no tokens match the specified kinds
        let customRules: [String: Any] = [
            "attribute_only": [
                "regex": "\\w+",
                "execution_mode": "swiftsyntax",
                "match_kinds": "attributeBuiltin", // Very specific kind that won't match normal code
                "message": "Found attribute",
            ],
        ]

        let example = Example("let value = 42")
        let violations = try violations(forExample: example, customRules: customRules)

        // Should produce no violations since there are no built-in attributes
        XCTAssertEqual(violations.count, 0)
    }
}

private extension StyleViolation {
    func isSuperfluousDisableCommandViolation(for ruleIdentifier: String) -> Bool {
        self.ruleIdentifier == SuperfluousDisableCommandRule.identifier &&
            reason.contains("SwiftLint rule '\(ruleIdentifier)' did not trigger a violation")
    }
}
