import SourceKittenFramework
@testable import SwiftLintCore
@testable import SwiftLintFramework
import TestHelpers
import Testing

// swiftlint:disable file_length

@Suite(.serialized, .rulesRegistered, .sourceKitRequestsWithoutRule)
struct CustomRulesTests {  // swiftlint:disable:this type_body_length
    private typealias Configuration = RegexConfiguration<CustomRules>

    private var testFile: SwiftLintFile { SwiftLintFile(path: "\(TestResources.path())/test.txt")! }

    @Test
    func customRuleConfigurationSetsCorrectlyWithMatchKinds() {
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
            #expect(configuration == compRules)
        } catch {
            Issue.record("Did not configure correctly")
        }
    }

    @Test
    func customRuleConfigurationSetsCorrectlyWithExcludedMatchKinds() {
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
            #expect(configuration == compRules)
        } catch {
            Issue.record("Did not configure correctly")
        }
    }

    @Test
    func customRuleConfigurationThrows() {
        let config = 17
        var customRulesConfig = CustomRulesConfiguration()
        #expect(throws: Issue.invalidConfiguration(ruleID: CustomRules.identifier)) {
            try customRulesConfig.apply(configuration: config)
        }
    }

    @Test
    func customRuleConfigurationMatchKindAmbiguity() {
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
        #expect(throws: expectedError) {
            try configuration.apply(configuration: configDict)
        }
    }

    @Test
    func customRuleConfigurationIgnoreInvalidRules() throws {
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

        #expect(customRulesConfig.customRuleConfigurations.count == 1)

        let identifier = customRulesConfig.customRuleConfigurations.first?.identifier
        #expect(identifier == "my_custom_rule")
    }

    @Test
    func customRules() {
        let (regexConfig, customRules) = getCustomRules()

        let file = SwiftLintFile(contents: "// My file with\n// a pattern")
        #expect(
            customRules.validate(file: file) == [
                StyleViolation(
                    ruleDescription: regexConfig.description,
                    severity: .warning,
                    location: Location(file: nil, line: 2, character: 6),
                    reason: regexConfig.message
                ),
            ]
        )
    }

    @Test
    func localDisableCustomRule() throws {
        let customRules: [String: Any] = [
            "custom": [
                "regex": "pattern",
                "match_kinds": "comment",
            ],
        ]
        let example = Example("//swiftlint:disable custom \n// file with a pattern")
        let violations = try violations(forExample: example, customRules: customRules)
        #expect(violations.isEmpty)
    }

    @Test
    func localDisableCustomRuleWithMultipleRules() {
        let (configs, customRules) = getCustomRulesWithTwoRules()
        let file = SwiftLintFile(contents: "//swiftlint:disable \(configs.1.identifier) \n// file with a pattern")
        #expect(
            customRules.validate(file: file) == [
                StyleViolation(
                    ruleDescription: configs.0.description,
                    severity: .warning,
                    location: Location(file: nil, line: 2, character: 16),
                    reason: configs.0.message
                ),
            ]
        )
    }

    @Test
    func customRulesIncludedDefault() {
        // Violation detected when included is omitted.
        let (_, customRules) = getCustomRules()
        let violations = customRules.validate(file: testFile)
        #expect(violations.count == 1)
    }

    @Test
    func customRulesIncludedExcludesFile() {
        var (regexConfig, customRules) = getCustomRules(["included": "\\.yml$"])

        var customRuleConfiguration = CustomRulesConfiguration()
        customRuleConfiguration.customRuleConfigurations = [regexConfig]
        customRules.configuration = customRuleConfiguration

        let violations = customRules.validate(file: testFile)
        #expect(violations.isEmpty)
    }

    @Test
    func customRulesExcludedExcludesFile() {
        var (regexConfig, customRules) = getCustomRules(["excluded": "\\.txt$"])

        var customRuleConfiguration = CustomRulesConfiguration()
        customRuleConfiguration.customRuleConfigurations = [regexConfig]
        customRules.configuration = customRuleConfiguration

        let violations = customRules.validate(file: testFile)
        #expect(violations.isEmpty)
    }

    @Test
    func customRulesExcludedArrayExcludesFile() {
        var (regexConfig, customRules) = getCustomRules(["excluded": ["\\.pdf$", "\\.txt$"]])

        var customRuleConfiguration = CustomRulesConfiguration()
        customRuleConfiguration.customRuleConfigurations = [regexConfig]
        customRules.configuration = customRuleConfiguration

        let violations = customRules.validate(file: testFile)
        #expect(violations.isEmpty)
    }

    @Test
    func customRulesCaptureGroup() {
        let (_, customRules) = getCustomRules([
            "regex": #"\ba\s+(\w+)"#,
            "capture_group": 1,
        ])
        let violations = customRules.validate(file: testFile)
        #expect(violations.count == 1)
        #expect(violations[0].location.line == 2)
        #expect(violations[0].location.character == 6)
    }

    // MARK: - superfluous_disable_command support

    @Test
    func customRulesTriggersSuperfluousDisableCommand() throws {
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
        #expect(violations.count == 1)
        #expect(violations[0].isSuperfluousDisableCommandViolation(for: "custom_rules"))
    }

    @Test
    func specificCustomRuleTriggersSuperfluousDisableCommand() throws {
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
        #expect(violations.count == 1)
        #expect(violations[0].isSuperfluousDisableCommandViolation(for: customRuleIdentifier))
    }

    @Test
    func specificAndCustomRulesTriggersSuperfluousDisableCommand() throws {
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

        #expect(violations.count == 2)
        #expect(violations[0].isSuperfluousDisableCommandViolation(for: "custom_rules"))
        #expect(violations[1].isSuperfluousDisableCommandViolation(for: "\(customRuleIdentifier)"))
    }

    @Test
    func customRulesViolationAndViolationOfSuperfluousDisableCommand() throws {
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

        #expect(violations.count == 2)
        #expect(violations[0].ruleIdentifier == customRuleIdentifier)
        #expect(violations[1].isSuperfluousDisableCommandViolation(for: customRuleIdentifier))
    }

    @Test
    func disablingCustomRulesDoesNotTriggerSuperfluousDisableCommand() throws {
        let customRules: [String: Any] = [
            "forbidden": [
                "regex": "FORBIDDEN",
            ],
        ]

        let example = Example("""
                              // swiftlint:disable:next custom_rules
                              let FORBIDDEN = 1
                              """)

        #expect(try violations(forExample: example, customRules: customRules).isEmpty)
    }

    @Test
    func multipleSpecificCustomRulesTriggersSuperfluousDisableCommand() throws {
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
        #expect(violations.count == 2)
        #expect(violations[0].isSuperfluousDisableCommandViolation(for: "forbidden"))
        #expect(violations[1].isSuperfluousDisableCommandViolation(for: "forbidden2"))
    }

    @Test
    func unviolatedSpecificCustomRulesTriggersSuperfluousDisableCommand() throws {
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
        #expect(violations.count == 1)
        #expect(violations[0].isSuperfluousDisableCommandViolation(for: "forbidden2"))
    }

    @Test
    func violatedSpecificAndGeneralCustomRulesTriggersSuperfluousDisableCommand() throws {
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
        #expect(violations.count == 1)
        #expect(violations[0].isSuperfluousDisableCommandViolation(for: "forbidden2"))
    }

    @Test
    func superfluousDisableCommandWithMultipleCustomRules() throws {
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

        #expect(violations.count == 3)
        #expect(violations[0].ruleIdentifier == "custom2")
        #expect(violations[1].isSuperfluousDisableCommandViolation(for: "custom1"))
        #expect(violations[2].isSuperfluousDisableCommandViolation(for: "custom3"))
    }

    @Test
    func violatedCustomRuleDoesNotTriggerSuperfluousDisableCommand() throws {
        let customRules: [String: Any] = [
            "dont_print": [
                "regex": "print\\("
            ],
        ]
        let example = Example(
            """
            // swiftlint:disable:next dont_print
            print("Hello, world")
            """)
        #expect(try violations(forExample: example, customRules: customRules).isEmpty)
    }

    @Test
    func disableAllDoesNotTriggerSuperfluousDisableCommand() throws {
        let customRules: [String: Any] = [
            "dont_print": [
                "regex": "print\\("
            ],
        ]
        let example = Example(
            """
            // swiftlint:disable:next all
            print("Hello, world")
            """)
        #expect(try violations(forExample: example, customRules: customRules).isEmpty)
    }

    @Test
    func disableAllAndDisableSpecificCustomRuleDoesNotTriggerSuperfluousDisableCommand() throws {
        let customRules: [String: Any] = [
            "dont_print": [
                "regex": "print\\("
            ],
        ]
        let example = Example(
            """
            // swiftlint:disable:next all dont_print
            print("Hello, world")
            """)
        #expect(try violations(forExample: example, customRules: customRules).isEmpty)
    }

    @Test
    func nestedCustomRuleDisablesDoNotTriggerSuperfluousDisableCommand() throws {
        let customRules: [String: Any] = [
            "rule1": [
                "regex": "pattern1"
            ],
            "rule2": [
                "regex": "pattern2"
            ],
        ]
        let example = Example(
            """
            // swiftlint:disable rule1
            // swiftlint:disable rule2
            let pattern2 = ""
            // swiftlint:enable rule2
            let pattern1 = ""
            // swiftlint:enable rule1
            """)
        #expect(try violations(forExample: example, customRules: customRules).isEmpty)
    }

    @Test
    func nestedAndOverlappingCustomRuleDisables() throws {
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

        #expect(violations.count == 1)
        #expect(violations[0].isSuperfluousDisableCommandViolation(for: "rule3"))
    }

    @Test
    func superfluousDisableRuleOrder() throws {
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

        #expect(violations.count == 4)
        #expect(violations[0].isSuperfluousDisableCommandViolation(for: "rule1"))
        #expect(violations[1].isSuperfluousDisableCommandViolation(for: "rule2"))
        #expect(violations[2].isSuperfluousDisableCommandViolation(for: "rule3"))
        #expect(violations[3].isSuperfluousDisableCommandViolation(for: "rule2"))
    }

    // MARK: - ExecutionMode Tests (Phase 1)

    @Test
    func regexConfigurationParsesExecutionMode() throws {
        let configDict = [
            "regex": "pattern",
            "execution_mode": "swiftsyntax",
        ]

        var regexConfig = Configuration(identifier: "test_rule")
        try regexConfig.apply(configuration: configDict)
        #expect(regexConfig.executionMode == .swiftsyntax)
    }

    @Test
    func regexConfigurationParsesSourceKitMode() throws {
        let configDict = [
            "regex": "pattern",
            "execution_mode": "sourcekit",
        ]

        var regexConfig = Configuration(identifier: "test_rule")
        try regexConfig.apply(configuration: configDict)
        #expect(regexConfig.executionMode == .sourcekit)
    }

    @Test
    func regexConfigurationWithoutModeIsDefault() throws {
        let configDict = [
            "regex": "pattern",
        ]

        var regexConfig = Configuration(identifier: "test_rule")
        try regexConfig.apply(configuration: configDict)
        #expect(regexConfig.executionMode == .default)
    }

    @Test
    func regexConfigurationRejectsInvalidMode() {
        let configDict = [
            "regex": "pattern",
            "execution_mode": "invalid_mode",
        ]

        var regexConfig = Configuration(identifier: "test_rule")
        #expect(throws: Issue.invalidConfiguration(ruleID: CustomRules.identifier)) {
            try regexConfig.apply(configuration: configDict)
        }
    }

    @Test
    func customRulesConfigurationParsesDefaultExecutionMode() throws {
        let configDict: [String: Any] = [
            "default_execution_mode": "swiftsyntax",
            "my_rule": [
                "regex": "pattern",
            ],
        ]

        var customRulesConfig = CustomRulesConfiguration()
        try customRulesConfig.apply(configuration: configDict)
        #expect(customRulesConfig.defaultExecutionMode == .swiftsyntax)
        #expect(customRulesConfig.customRuleConfigurations.count == 1)
        #expect(customRulesConfig.customRuleConfigurations[0].executionMode == .default)
    }

    @Test
    func customRulesAppliesDefaultModeToRulesWithoutExplicitMode() throws {
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
        #expect(customRulesConfig.defaultExecutionMode == .sourcekit)
        #expect(customRulesConfig.customRuleConfigurations.count == 2)

        // rule1 should have default mode
        let rule1 = customRulesConfig.customRuleConfigurations.first { $0.identifier == "rule1" }
        #expect(rule1?.executionMode == .default)

        // rule2 should keep its explicit mode
        let rule2 = customRulesConfig.customRuleConfigurations.first { $0.identifier == "rule2" }
        #expect(rule2?.executionMode == .swiftsyntax)
    }

    @Test
    func customRulesConfigurationRejectsInvalidDefaultMode() {
        let configDict: [String: Any] = [
            "default_execution_mode": "invalid",
            "my_rule": [
                "regex": "pattern",
            ],
        ]

        var customRulesConfig = CustomRulesConfiguration()
        #expect(throws: Issue.invalidConfiguration(ruleID: CustomRules.identifier)) {
            try customRulesConfig.apply(configuration: configDict)
        }
    }

    @Test
    func executionModeIncludedInCacheDescription() {
        var regexConfig = Configuration(identifier: "test_rule")
        regexConfig.regex = "pattern"
        regexConfig.executionMode = .swiftsyntax

        #expect(regexConfig.cacheDescription.contains("swiftsyntax"))
    }

    @Test
    func executionModeAffectsHash() {
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
        #expect(config1.hashValue != config2.hashValue)
        #expect(config1.hashValue != config3.hashValue)
        #expect(config2.hashValue != config3.hashValue)
    }

    // MARK: - Phase 2 Tests: SwiftSyntax Mode Execution

    @Test
    func customRuleUsesSwiftSyntaxModeWhenConfigured() throws {
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

        #expect(violations.count == 1)
        #expect(violations[0].ruleIdentifier == "no_foo")
        #expect(violations[0].reason == "Don't use foo")
        #expect(violations[0].location.line == 1)
        #expect(violations[0].location.character == 5)
    }

    @Test
    func customRuleWithoutMatchKindsUsesSwiftSyntaxByDefault() throws {
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
        #expect(violations.count == 2)
        #expect(violations[0].location.line == 1)
        #expect(violations[0].location.character == 5)
        #expect(violations[1].location.line == 1)
        #expect(violations[1].location.character == 18)
    }

    @Test
    func customRuleDefaultsToSourceKitWhenNoModeSpecified() throws {
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
        #expect(violations.count == 1)
        #expect(violations[0].ruleIdentifier == "no_foo")
        #expect(violations[0].reason == "Don't use foo")

        // Verify the rule is effectively SourceKit-free
        let configuration = try SwiftLintFramework.Configuration(dict: [
            "only_rules": ["custom_rules"],
            "custom_rules": customRules,
        ])

        guard let customRule = configuration.rules.customRules else {
            Issue.record("Expected CustomRules in configuration")
            return
        }

        #expect(
            !customRule.isEffectivelySourceKitFree,
            "Rule depends on SourceKit")
    }

    @Test
    func customRuleWithMatchKindsUsesSwiftSyntaxWhenConfigured() throws {
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
        #expect(violations.count == 1)
        #expect(violations[0].location.line == 1)
        #expect(violations[0].location.character == 23)  // Position of 'foo' in comment // Position of 'foo' in comment
    }

    @Test
    func customRuleWithKindFilteringDefaultsToSourceKit() throws {
        // When using kind filtering without specifying mode, it should default to sourcekit
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
        #expect(violations.count == 2)
        #expect(violations[0].location.character == 5)  // 'foo' // 'foo'
        #expect(violations[1].location.character == 11)  // '42' // '42'

        // Verify the rule is effectively SourceKit-free
        let configuration = try SwiftLintFramework.Configuration(dict: [
            "only_rules": ["custom_rules"],
            "custom_rules": customRules,
        ])

        guard let customRule = configuration.rules.customRules else {
            Issue.record("Expected CustomRules in configuration")
            return
        }

        #expect(
            !customRule.isEffectivelySourceKitFree,
            "Rule with kind filtering should default to sourcekit mode")
    }

    @Test
    func customRuleWithExcludedMatchKindsUsesSwiftSyntaxWithDefaultMode() throws {
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
        #expect(violations.count == 2)
        #expect(violations[0].location.line == 1)
        #expect(violations[0].location.character == 5)  // 'foo' in variable name // 'foo' in variable name
        #expect(violations[1].location.line == 2)
        #expect(violations[1].location.character == 5)  // 'foo' in foobar // 'foo' in foobar
    }

    @Test
    func swiftSyntaxModeProducesSameResultsAsSourceKitForSimpleRules() throws {
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
        #expect(swiftSyntaxViolations.count == sourceKitViolations.count)
        #expect(swiftSyntaxViolations.count == 3)  // Two in comments, one in string // Two in comments, one in string

        // Verify locations match
        for (ssViolation, skViolation) in zip(swiftSyntaxViolations, sourceKitViolations) {
            #expect(ssViolation.location.line == skViolation.location.line)
            #expect(ssViolation.location.character == skViolation.location.character)
            #expect(ssViolation.reason == skViolation.reason)
        }
    }

    @Test
    func swiftSyntaxModeWithCaptureGroups() throws {
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

        #expect(violations.count == 2)
        // First capture group should highlight just the number part
        #expect(violations[0].location.character == 13)  // Position of "42" // Position of "42"
        #expect(violations[1].location.character == 25)  // Position of "100" // Position of "100"
    }

    @Test
    func swiftSyntaxModeRespectsIncludedExcludedPaths() throws {
        // Verify that included/excluded path filtering works in SwiftSyntax mode
        var regexConfig = Configuration(identifier: "test_rule")
        regexConfig.regex = "pattern"
        regexConfig.executionMode = .swiftsyntax
        regexConfig.included = [try RegularExpression(pattern: "\\.swift$")]
        regexConfig.excluded = [try RegularExpression(pattern: "Tests")]

        #expect(regexConfig.shouldValidate(filePath: "/path/to/file.swift"))
        #expect(!regexConfig.shouldValidate(filePath: "/path/to/file.m"))
        #expect(!regexConfig.shouldValidate(filePath: "/path/to/Tests/file.swift"))
    }

    // MARK: - only_rules support

    @Test
    func onlyRulesWithCustomRules() throws {
        let ruleIdentifierToEnable = "aaa"
        let violations = try testOnlyRulesWithCustomRules([ruleIdentifierToEnable])
        #expect(violations.count == 1)
        #expect(violations[0].ruleIdentifier == ruleIdentifierToEnable)
    }

    @Test
    func onlyRulesWithIndividualIdentifiers() throws {
        let customRuleIdentifiers = ["aaa", "bbb"]
        let violationsWithIndividualRuleIdentifiers = try testOnlyRulesWithCustomRules(customRuleIdentifiers)
        #expect(violationsWithIndividualRuleIdentifiers.count == 2)
        #expect(
            violationsWithIndividualRuleIdentifiers.map { $0.ruleIdentifier } == customRuleIdentifiers
        )
        let violationsWithCustomRulesIdentifier = try testOnlyRulesWithCustomRules(["custom_rules"])
        #expect(violationsWithIndividualRuleIdentifiers == violationsWithCustomRulesIdentifier)
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
            Issue.record("Failed regex config")
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

    @Test
    func swiftSyntaxModeWithMatchKindsProducesCorrectResults() throws {
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
        #expect(violations.count == 3)

        // Verify the locations correspond to keywords
        let expectedLocations = [
            (line: 1, character: 1),  // 'let'
            (line: 2, character: 1),  // 'func'
            (line: 3, character: 5),  // 'return'
        ]

        for (index, expected) in expectedLocations.enumerated() {
            #expect(violations[index].location.line == expected.line)
            #expect(violations[index].location.character == expected.character)
        }
    }

    @Test
    func swiftSyntaxModeWithExcludedKindsFiltersCorrectly() throws {
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
        #expect(violations.count == 2)
    }

    @Test
    func swiftSyntaxModeHandlesComplexKindMatching() throws {
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
        #expect(violations.count >= 3)
    }

    @Test
    func swiftSyntaxModeWorksWithCaptureGroups() throws {
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

        #expect(violations.count == 1)
        #expect(violations[0].location.character == 17)  // Start of "Hello, World!" content
    }

    @Test
    func swiftSyntaxModeRespectsSourceKitModeOverride() throws {
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
        #expect(violations.count == 1)
        #expect(violations[0].location.character == 5)
    }

    @Test
    func swiftSyntaxModeHandlesEmptyBridging() throws {
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
        #expect(violations.isEmpty)
    }

    private func testOnlyRulesWithCustomRules(_ onlyRulesIdentifiers: [String]) throws -> [StyleViolation] {
        let customRules: [String: Any] = [
            "aaa": [
                "regex": "aaa"
            ],
            "bbb": [
                "regex": "bbb"
            ],
        ]
        let example = Example("""
                              let a = "aaa"
                              let b = "bbb"
                              """)
        let configDict: [String: Any] = [
            "only_rules": onlyRulesIdentifiers,
            "custom_rules": customRules,
        ]
        let configuration = try SwiftLintFramework.Configuration(dict: configDict)
        return TestHelpers.violations(example.skipWrappingInCommentTest(), config: configuration)
    }
}

private extension StyleViolation {
    func isSuperfluousDisableCommandViolation(for ruleIdentifier: String) -> Bool {
        self.ruleIdentifier == SuperfluousDisableCommandRule.identifier &&
            reason.contains("SwiftLint rule '\(ruleIdentifier)' did not trigger a violation")
    }
}
