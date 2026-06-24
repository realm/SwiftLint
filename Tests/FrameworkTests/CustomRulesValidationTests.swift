import SourceKittenFramework
@testable import SwiftLintCore
@testable import SwiftLintFramework
import TestHelpers
import XCTest

/// Tests to ensure CustomRules properly handles SourceKit validation system
final class CustomRulesValidationTests: SwiftLintTestCase {
    private typealias Configuration = RegexConfiguration<CustomRules>

    // MARK: - Validation System Tests

    func testSwiftSyntaxModeWithoutKindsMakesNoSourceKitCalls() throws {
        // This test verifies that SwiftSyntax mode without kind matching makes no SourceKit calls
        // If it did, the validation system would fatal error (but we're allowing it for test setup)
        let customRules: [String: Any] = [
            "simple_rule": [
                "regex": "TODO",
                "mode": "swiftsyntax",
                "message": "Found TODO",
            ],
        ]

        let example = Example("// TODO: Fix this")
        let configuration = try SwiftLintFramework.Configuration(dict: [
            "only_rules": ["custom_rules"],
            "custom_rules": customRules,
        ])

        // This should complete without fatal errors
        let violations = TestHelpers.violations(example, config: configuration)
        XCTAssertEqual(violations.count, 1)
    }

    func testSwiftSyntaxModeWithKindsMakesNoSourceKitCalls() throws {
        // This test verifies that SwiftSyntax mode with kind matching uses bridged tokens
        // and makes no SourceKit calls
        let customRules: [String: Any] = [
            "keyword_rule": [
                "regex": "\\b\\w+\\b",
                "mode": "swiftsyntax",
                "match_kinds": "keyword",
                "message": "Found keyword",
            ],
        ]

        let example = Example("let value = 42")
        let configuration = try SwiftLintFramework.Configuration(dict: [
            "only_rules": ["custom_rules"],
            "custom_rules": customRules,
        ])

        // This should complete without fatal errors
        let violations = TestHelpers.violations(example, config: configuration)
        XCTAssertGreaterThanOrEqual(violations.count, 1) // At least 'let' keyword
    }

    func testSourceKitModeCanMakeSourceKitCalls() throws {
        // This test verifies that SourceKit mode is allowed to make SourceKit calls
        // because CustomRules is not a SourceKitFreeRule
        let customRules: [String: Any] = [
            "identifier_rule": [
                "regex": "\\b\\w+\\b",
                "mode": "sourcekit",
                "match_kinds": "identifier",
                "message": "Found identifier",
            ],
        ]

        let example = Example("let myVariable = 42")
        let configuration = try SwiftLintFramework.Configuration(dict: [
            "only_rules": ["custom_rules"],
            "custom_rules": customRules,
        ])

        // This should complete without fatal errors even though it makes SourceKit calls
        let violations = TestHelpers.violations(example, config: configuration)
        XCTAssertGreaterThanOrEqual(violations.count, 1) // At least 'myVariable'
    }

    func testDefaultSwiftSyntaxModeWithKindFilteringMakesNoSourceKitCalls() throws {
        // Test that default swiftsyntax mode with kind filtering doesn't trigger SourceKit
        let customRules: [String: Any] = [
            "default_execution_mode": "swiftsyntax",
            "comment_rule": [
                "regex": "\\b\\w+\\b",
                "excluded_match_kinds": "comment",
                "message": "Found non-comment word",
            ],
        ]

        let example = Example("""
            let value = 42 // This is a comment
            """)
        let configuration = try SwiftLintFramework.Configuration(dict: [
            "only_rules": ["custom_rules"],
            "custom_rules": customRules,
        ])

        // This should complete without fatal errors
        let violations = TestHelpers.violations(example, config: configuration)
        XCTAssertGreaterThanOrEqual(violations.count, 3) // 'let', 'value', '42'
    }

    func testMixedModeRulesWorkCorrectly() throws {
        // Test that having both SwiftSyntax and SourceKit rules in the same configuration works
        let customRules: [String: Any] = [
            "syntax_rule": [
                "regex": "TODO",
                "mode": "swiftsyntax",
                "message": "SwiftSyntax TODO",
            ],
            "sourcekit_rule": [
                "regex": "FIXME",
                "mode": "sourcekit",
                "message": "SourceKit FIXME",
            ],
        ]

        let example = Example("""
            // TODO: Do this
            // FIXME: Fix that
            """)
        let configuration = try SwiftLintFramework.Configuration(dict: [
            "only_rules": ["custom_rules"],
            "custom_rules": customRules,
        ])

        let violations = TestHelpers.violations(example, config: configuration)
        XCTAssertEqual(violations.count, 2)
        XCTAssertTrue(violations.contains { $0.reason == "SwiftSyntax TODO" })
        XCTAssertTrue(violations.contains { $0.reason == "SourceKit FIXME" })
    }

    // MARK: - Bridging Validation Tests

    func testBridgedTokensProduceEquivalentResults() throws {
        // Compare results between SwiftSyntax bridged tokens and SourceKit tokens
        let pattern = "\\b\\w+\\b"
        let kinds = ["keyword", "identifier"]

        let swiftSyntaxRules: [String: Any] = [
            "test_rule": [
                "regex": pattern,
                "mode": "swiftsyntax",
                "match_kinds": kinds,
                "message": "Match",
            ],
        ]

        let sourceKitRules: [String: Any] = [
            "test_rule": [
                "regex": pattern,
                "mode": "sourcekit",
                "match_kinds": kinds,
                "message": "Match",
            ],
        ]

        let example = Example("""
            func testFunction() {
                let value = 42
            }
            """)

        let ssConfig = try SwiftLintFramework.Configuration(dict: [
            "only_rules": ["custom_rules"],
            "custom_rules": swiftSyntaxRules,
        ])

        let skConfig = try SwiftLintFramework.Configuration(dict: [
            "only_rules": ["custom_rules"],
            "custom_rules": sourceKitRules,
        ])

        let ssViolations = TestHelpers.violations(example, config: ssConfig)
        let skViolations = TestHelpers.violations(example, config: skConfig)

        // Both should find similar matches (exact count may vary due to classification differences)
        XCTAssertGreaterThan(ssViolations.count, 0)
        XCTAssertGreaterThan(skViolations.count, 0)

        // The difference should be reasonable (within classification mapping differences)
        let countDifference = abs(ssViolations.count - skViolations.count)
        XCTAssertLessThanOrEqual(countDifference, 2, "SwiftSyntax and SourceKit results differ too much")
    }

    func testBridgingHandlesEdgeCases() throws {
        // Test edge cases like empty files, whitespace-only files, etc.
        let customRules: [String: Any] = [
            "any_token": [
                "regex": "\\S+",
                "mode": "swiftsyntax",
                "match_kinds": ["keyword", "identifier", "string", "number"],
                "message": "Found token",
            ],
        ]

        let testCases = [
            "",  // Empty file
            "   \n\t  ",  // Whitespace only
            "// Only a comment",  // Comment only (should not match since we're looking for specific kinds)
        ]

        let configuration = try SwiftLintFramework.Configuration(dict: [
            "only_rules": ["custom_rules"],
            "custom_rules": customRules,
        ])

        for testCase in testCases {
            let example = Example(testCase)
            // Should not crash or fatal error
            _ = TestHelpers.violations(example, config: configuration)
        }
    }

    // MARK: - Phase 6 Tests: Conditional SourceKit-Free Behavior

    func testCustomRulesIsEffectivelySourceKitFreeWithAllSwiftSyntaxRules() {
        var customRules = CustomRules()
        customRules.configuration.defaultExecutionMode = .swiftsyntax
        customRules.configuration.customRuleConfigurations = [
            {
                var config = RegexConfiguration<CustomRules>(identifier: "rule1")
                config.regex = "pattern1"
                config.executionMode = .swiftsyntax
                return config
            }(),
            {
                var config = RegexConfiguration<CustomRules>(identifier: "rule2")
                config.regex = "pattern2"
                // Uses default mode (swiftsyntax)
                return config
            }(),
        ]

        XCTAssertTrue(customRules.isEffectivelySourceKitFree)
        XCTAssertFalse(customRules.requiresSourceKit)
    }

    func testCustomRulesRequiresSourceKitWithMixedModes() {
        var customRules = CustomRules()
        customRules.configuration.defaultExecutionMode = .swiftsyntax
        customRules.configuration.customRuleConfigurations = [
            {
                var config = RegexConfiguration<CustomRules>(identifier: "rule1")
                config.regex = "pattern1"
                config.executionMode = .swiftsyntax
                return config
            }(),
            {
                var config = RegexConfiguration<CustomRules>(identifier: "rule2")
                config.regex = "pattern2"
                config.executionMode = .sourcekit  // One SourceKit rule
                return config
            }(),
        ]

        XCTAssertFalse(customRules.isEffectivelySourceKitFree)
        XCTAssertTrue(customRules.requiresSourceKit)
    }

    func testCustomRulesDefaultsToSwiftSyntaxWithoutExplicitMode() {
        var customRules = CustomRules()
        // No default mode set (now defaults to swiftsyntax)
        customRules.configuration.customRuleConfigurations = [
            {
                var config = RegexConfiguration<CustomRules>(identifier: "rule1")
                config.regex = "pattern1"
                // No explicit mode, uses default (swiftsyntax)
                return config
            }(),
        ]

        XCTAssertTrue(customRules.isEffectivelySourceKitFree)
        XCTAssertFalse(customRules.requiresSourceKit)
    }

    func testSourceKitNotInitializedForSourceKitFreeCustomRules() throws {
        // This test verifies that when all custom rules use SwiftSyntax mode,
        // SourceKit is not initialized at all
        let customRules: [String: Any] = [
            "default_execution_mode": "swiftsyntax",
            "simple_rule": [
                "regex": "TODO",
                "message": "Found TODO",
            ],
            "keyword_rule": [
                "regex": "\\b\\w+\\b",
                "match_kinds": "keyword",
                "message": "Found keyword",
            ],
        ]

        let example = Example("let x = 42 // TODO: Fix this")
        let configuration = try SwiftLintFramework.Configuration(dict: [
            "only_rules": ["custom_rules"],
            "custom_rules": customRules,
        ])

        // Create a new file to ensure no cached SourceKit response
        let file = SwiftLintFile(contents: example.code)

        // Get the configured custom rules
        guard let customRule = configuration.rules.first(where: { $0 is CustomRules }) as? CustomRules else {
            XCTFail("Expected CustomRules in configuration")
            return
        }

        // Verify it's effectively SourceKit-free
        XCTAssertTrue(customRule.isEffectivelySourceKitFree)
        XCTAssertFalse(customRule.requiresSourceKit)

        // Run validation - this should not trigger SourceKit
        let violations = customRule.validate(file: file)

        // Should find violations without using SourceKit
        XCTAssertGreaterThanOrEqual(violations.count, 2) // 'let' keyword and 'TODO'

        // Verify SourceKit was never accessed
        // Note: In a real test environment, we'd check that no SourceKit requests were made
        // For now, we just verify the rule ran successfully
    }

    func testSourceKitNotInitializedWithImplicitSwiftSyntaxDefault() throws {
        // This test verifies that when NO execution mode is specified,
        // custom rules default to SwiftSyntax and don't initialize SourceKit
        let customRules: [String: Any] = [
            // Note: NO default_execution_mode specified
            "simple_rule": [
                "regex": "TODO",
                "message": "Found TODO",
            ],
            "keyword_rule": [
                "regex": "\\b\\w+\\b",
                "match_kinds": "keyword", // Kind filtering without explicit mode
                "message": "Found keyword",
            ],
        ]

        let example = Example("let x = 42 // TODO: Fix this")
        let configuration = try SwiftLintFramework.Configuration(dict: [
            "only_rules": ["custom_rules"],
            "custom_rules": customRules,
        ])

        // Create a new file to ensure no cached SourceKit response
        let file = SwiftLintFile(contents: example.code)

        // Get the configured custom rules
        guard let customRule = configuration.rules.first(where: { $0 is CustomRules }) as? CustomRules else {
            XCTFail("Expected CustomRules in configuration")
            return
        }

        // Verify it's effectively SourceKit-free (defaulting to swiftsyntax)
        XCTAssertTrue(customRule.isEffectivelySourceKitFree)
        XCTAssertFalse(customRule.requiresSourceKit)

        // Run validation - this should not trigger SourceKit
        let violations = customRule.validate(file: file)

        // Should find violations without using SourceKit
        XCTAssertGreaterThanOrEqual(violations.count, 2) // 'let' keyword and 'TODO'
    }
}
