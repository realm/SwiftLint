@testable import SwiftLintCore
@testable import SwiftLintFramework
import TestHelpers
import XCTest

/// Tests that custom (regex) rules can be selected via `--only-rule` from the command line and via
/// `only_rules:` from a configuration file.
///
/// Before the fix, `activateCustomRuleIdentifiers` only expanded custom rules for the
/// `.onlyConfiguration` mode (and even there, only when `custom_rules` itself was the listed
/// identifier), so:
///
/// * `--only-rule custom_rules` ran the parent rule but had every individual custom rule filtered
///   out, producing zero violations.
/// * `--only-rule my_custom_rule` left the parent `custom_rules` rule out of the resulting rule set
///   entirely, so the custom rule never executed.
/// * `only_rules: [my_custom_rule]` had the same problem as the second case.
final class OnlyRuleCustomRulesTests: SwiftLintTestCase {
    /// Instance-scoped so that a non-`Sendable` `[String: Any]` literal is not held as shared
    /// mutable global state. A `static let` here is rejected by the Swift 6 language mode that
    /// Bazel CI compiles with.
    private var customRulesDict: [String: Any] {
        [
            "custom_rules": [
                "rule_a": ["name": "RuleA", "regex": "a", "message": "msg"],
                "rule_b": ["name": "RuleB", "regex": "b", "message": "msg"],
            ],
        ]
    }

    // MARK: - `--only-rule` from the command line

    func testOnlyRuleFromCommandLineForIndividualCustomRule() throws {
        let config = try Configuration(dict: customRulesDict, onlyRule: ["rule_a"])
        let activeCustomRules = activeCustomRuleIdentifiers(in: config)
        XCTAssertEqual(activeCustomRules, ["rule_a"])
    }

    func testOnlyRuleFromCommandLineForCustomRulesParentEnablesAll() throws {
        let config = try Configuration(dict: customRulesDict, onlyRule: ["custom_rules"])
        let activeCustomRules = activeCustomRuleIdentifiers(in: config)
        XCTAssertEqual(activeCustomRules, ["rule_a", "rule_b"])
    }

    func testOnlyRuleFromCommandLineForUnrelatedRuleDoesNotEnableCustomRules() throws {
        let config = try Configuration(dict: customRulesDict, onlyRule: ["line_length"])
        XCTAssertNil(
            config.rules.first(where: { $0 is CustomRules }),
            "`--only-rule` for an unrelated built-in rule must not pull in the custom_rules parent rule"
        )
    }

    // MARK: - `only_rules:` in configuration

    func testOnlyRulesInConfigForIndividualCustomRule() throws {
        var dict = customRulesDict
        dict["only_rules"] = ["rule_a"]
        let config = try Configuration(dict: dict)
        let activeCustomRules = activeCustomRuleIdentifiers(in: config)
        XCTAssertEqual(activeCustomRules, ["rule_a"])
    }

    // MARK: - Helpers

    /// Returns the identifiers of the custom rule configurations that remain active in `config`'s
    /// `resultingRules`, sorted for deterministic comparison. Empty if the parent `custom_rules`
    /// rule was filtered out entirely.
    private func activeCustomRuleIdentifiers(in config: Configuration) -> [String] {
        guard let customRules = config.rules.first(where: { $0 is CustomRules }) as? CustomRules else {
            return []
        }
        return customRules.configuration.customRuleConfigurations.map(\.identifier).sorted()
    }
}
