import SourceKittenFramework
@testable import SwiftLintBuiltInRules
@testable import SwiftLintCore
import XCTest

final class RuleConfigurationTests: SwiftLintTestCase {
    private let defaultNestingConfiguration = NestingConfiguration(
        typeLevel: SeverityLevelsConfiguration(warning: 0),
        functionLevel: SeverityLevelsConfiguration(warning: 0)
    )

    func testNestingConfigurationSetsCorrectly() {
        let config = [
            "type_level": [
                "warning": 7, "error": 17
            ],
            "function_level": [
                "warning": 8, "error": 18
            ],
            "check_nesting_in_closures_and_statements": false,
            "always_allow_one_type_in_functions": true,
        ] as [String: any Sendable]
        var nestingConfig = defaultNestingConfiguration
        do {
            try nestingConfig.apply(configuration: config)
            XCTAssertEqual(nestingConfig.typeLevel.warning, 7)
            XCTAssertEqual(nestingConfig.functionLevel.warning, 8)
            XCTAssertEqual(nestingConfig.typeLevel.error, 17)
            XCTAssertEqual(nestingConfig.functionLevel.error, 18)
            XCTAssert(nestingConfig.alwaysAllowOneTypeInFunctions)
            XCTAssert(!nestingConfig.checkNestingInClosuresAndStatements)
        } catch {
            XCTFail("Failed to configure nested configurations")
        }
    }

    func testNestingConfigurationThrowsOnBadConfig() {
        let config = 17
        var nestingConfig = defaultNestingConfiguration
        checkError(Issue.invalidConfiguration(ruleID: NestingRule.identifier)) {
            try nestingConfig.apply(configuration: config)
        }
    }

    func testSeverityWorksAsOnlyParameter() throws {
        var config = AttributesConfiguration()
        XCTAssertEqual(config.severity, .warning)
        try config.apply(configuration: "error")
        XCTAssertEqual(config.severity, .error)
    }

    func testSeverityConfigurationFromString() {
        let config = "Warning"
        let comp = SeverityConfiguration<RuleMock>(.warning)
        var severityConfig = SeverityConfiguration<RuleMock>(.error)
        do {
            try severityConfig.apply(configuration: config)
            XCTAssertEqual(severityConfig, comp)
        } catch {
            XCTFail("Failed to configure severity from string")
        }
    }

    func testSeverityConfigurationFromDictionary() {
        let config = ["severity": "warning"]
        let comp = SeverityConfiguration<RuleMock>(.warning)
        var severityConfig = SeverityConfiguration<RuleMock>(.error)
        do {
            try severityConfig.apply(configuration: config)
            XCTAssertEqual(severityConfig, comp)
        } catch {
            XCTFail("Failed to configure severity from dictionary")
        }
    }

    func testSeverityConfigurationThrowsNothingApplied() throws {
        let config = 17
        var severityConfig = SeverityConfiguration<RuleMock>(.error)
        checkError(Issue.nothingApplied(ruleID: RuleMock.identifier)) {
            try severityConfig.apply(configuration: config)
        }
    }

    func testSeverityConfigurationThrowsInvalidConfiguration() {
        let config = "foo"
        var severityConfig = SeverityConfiguration<RuleMock>(.warning)
        checkError(Issue.invalidConfiguration(ruleID: RuleMock.identifier)) {
            try severityConfig.apply(configuration: config)
        }
    }

    func testSeverityLevelConfigParams() {
        let severityConfig = SeverityLevelsConfiguration<RuleMock>(warning: 17, error: 7)
        XCTAssertEqual(
            severityConfig.params,
            [RuleParameter(severity: .error, value: 7), RuleParameter(severity: .warning, value: 17)]
        )
    }

    func testSeverityLevelConfigPartialParams() {
        let severityConfig = SeverityLevelsConfiguration<RuleMock>(warning: 17, error: nil)
        XCTAssertEqual(severityConfig.params, [RuleParameter(severity: .warning, value: 17)])
    }

    func testSeverityLevelConfigApplyNilErrorValue() throws {
        var severityConfig = SeverityLevelsConfiguration<RuleMock>(warning: 17, error: 20)
        try severityConfig.apply(configuration: ["error": nil, "warning": 18])
        XCTAssertEqual(severityConfig.params, [RuleParameter(severity: .warning, value: 18)])
    }

    func testSeverityLevelConfigApplyMissingErrorValue() throws {
        var severityConfig = SeverityLevelsConfiguration<RuleMock>(warning: 17, error: 20)
        try severityConfig.apply(configuration: ["warning": 18])
        XCTAssertEqual(severityConfig.params, [RuleParameter(severity: .warning, value: 18)])
    }

    func testRegexConfigurationThrows() {
        let config = 17
        var regexConfig = RegexConfiguration<RuleMock>(identifier: "")
        checkError(Issue.invalidConfiguration(ruleID: RuleMock.identifier)) {
            try regexConfig.apply(configuration: config)
        }
    }

    func testRegexRuleDescription() {
        var regexConfig = RegexConfiguration<RuleMock>(identifier: "regex")
        XCTAssertEqual(regexConfig.description, RuleDescription(identifier: "regex",
                                                                name: "regex",
                                                                description: "", kind: .style))
        regexConfig.name = "name"
        XCTAssertEqual(regexConfig.description, RuleDescription(identifier: "regex",
                                                                name: "name",
                                                                description: "", kind: .style))
    }

    func testTrailingWhitespaceConfigurationThrowsOnBadConfig() {
        let config = "unknown"
        var configuration = TrailingWhitespaceConfiguration(ignoresEmptyLines: false,
                                                            ignoresComments: true)
        checkError(Issue.invalidConfiguration(ruleID: TrailingWhitespaceRule.identifier)) {
            try configuration.apply(configuration: config)
        }
    }

    func testTrailingWhitespaceConfigurationInitializerSetsIgnoresEmptyLines() {
        let configuration1 = TrailingWhitespaceConfiguration(ignoresEmptyLines: false,
                                                             ignoresComments: true)
        XCTAssertFalse(configuration1.ignoresEmptyLines)

        let configuration2 = TrailingWhitespaceConfiguration(ignoresEmptyLines: true,
                                                             ignoresComments: true)
        XCTAssertTrue(configuration2.ignoresEmptyLines)
    }

    func testTrailingWhitespaceConfigurationInitializerSetsIgnoresComments() {
        let configuration1 = TrailingWhitespaceConfiguration(ignoresEmptyLines: false,
                                                             ignoresComments: true)
        XCTAssertTrue(configuration1.ignoresComments)

        let configuration2 = TrailingWhitespaceConfiguration(ignoresEmptyLines: false,
                                                             ignoresComments: false)
        XCTAssertFalse(configuration2.ignoresComments)
    }

    func testTrailingWhitespaceConfigurationApplyConfigurationSetsIgnoresEmptyLines() {
        var configuration = TrailingWhitespaceConfiguration(ignoresEmptyLines: false,
                                                            ignoresComments: true)
        do {
            let config1 = ["ignores_empty_lines": true]
            try configuration.apply(configuration: config1)
            XCTAssertTrue(configuration.ignoresEmptyLines)

            let config2 = ["ignores_empty_lines": false]
            try configuration.apply(configuration: config2)
            XCTAssertFalse(configuration.ignoresEmptyLines)
        } catch {
            XCTFail("Failed to apply ignores_empty_lines")
        }
    }

    func testTrailingWhitespaceConfigurationApplyConfigurationSetsIgnoresComments() {
        var configuration = TrailingWhitespaceConfiguration(ignoresEmptyLines: false,
                                                            ignoresComments: true)
        do {
            let config1 = ["ignores_comments": true]
            try configuration.apply(configuration: config1)
            XCTAssertTrue(configuration.ignoresComments)

            let config2 = ["ignores_comments": false]
            try configuration.apply(configuration: config2)
            XCTAssertFalse(configuration.ignoresComments)
        } catch {
            XCTFail("Failed to apply ignores_comments")
        }
    }

    func testTrailingWhitespaceConfigurationCompares() {
        let configuration1 = TrailingWhitespaceConfiguration(ignoresEmptyLines: false,
                                                             ignoresComments: true)
        let configuration2 = TrailingWhitespaceConfiguration(ignoresEmptyLines: true,
                                                             ignoresComments: true)
        XCTAssertNotEqual(configuration1, configuration2)

        let configuration3 = TrailingWhitespaceConfiguration(ignoresEmptyLines: true,
                                                             ignoresComments: true)
        XCTAssertEqual(configuration2, configuration3)

        let configuration4 = TrailingWhitespaceConfiguration(ignoresEmptyLines: false,
                                                             ignoresComments: false)

        XCTAssertNotEqual(configuration1, configuration4)

        let configuration5 = TrailingWhitespaceConfiguration(ignoresEmptyLines: true,
                                                             ignoresComments: false)

        XCTAssertNotEqual(configuration1, configuration5)
    }

    func testTrailingWhitespaceConfigurationApplyConfigurationUpdatesSeverityConfiguration() {
        var configuration = TrailingWhitespaceConfiguration(
            severityConfiguration: .warning,
            ignoresEmptyLines: false,
            ignoresComments: true
        )

        do {
            try configuration.apply(configuration: ["severity": "error"])
            XCTAssertEqual(configuration.severityConfiguration.severity, .error)
        } catch {
            XCTFail("Failed to apply severity")
        }
    }

    func testOverriddenSuperCallConfigurationFromDictionary() {
        var configuration = OverriddenSuperCallConfiguration()
        XCTAssertTrue(configuration.resolvedMethodNames.contains("viewWillAppear(_:)"))

        let conf1 = ["severity": "error", "excluded": "viewWillAppear(_:)"]
        do {
            try configuration.apply(configuration: conf1)
            XCTAssertEqual(configuration.severityConfiguration.severity, .error)
            XCTAssertFalse(configuration.resolvedMethodNames.contains("*"))
            XCTAssertFalse(configuration.resolvedMethodNames.contains("viewWillAppear(_:)"))
            XCTAssertTrue(configuration.resolvedMethodNames.contains("viewWillDisappear(_:)"))
        } catch {
            XCTFail("Failed to apply configuration for \(conf1)")
        }

        let conf2 = [
            "severity": "error",
            "excluded": "viewWillAppear(_:)",
            "included": ["*", "testMethod1()", "testMethod2(_:)"],
        ] as [String: any Sendable]
        do {
            try configuration.apply(configuration: conf2)
            XCTAssertEqual(configuration.severityConfiguration.severity, .error)
            XCTAssertFalse(configuration.resolvedMethodNames.contains("*"))
            XCTAssertFalse(configuration.resolvedMethodNames.contains("viewWillAppear(_:)"))
            XCTAssertTrue(configuration.resolvedMethodNames.contains("viewWillDisappear(_:)"))
            XCTAssertTrue(configuration.resolvedMethodNames.contains("testMethod1()"))
            XCTAssertTrue(configuration.resolvedMethodNames.contains("testMethod2(_:)"))
        } catch {
            XCTFail("Failed to apply configuration for \(conf2)")
        }

        let conf3 = [
            "severity": "warning",
            "excluded": "*",
            "included": ["testMethod1()", "testMethod2(_:)"],
        ] as [String: any Sendable]
        do {
            try configuration.apply(configuration: conf3)
            XCTAssertEqual(configuration.severityConfiguration.severity, .warning)
            XCTAssertEqual(configuration.resolvedMethodNames.count, 2)
            XCTAssertFalse(configuration.resolvedMethodNames.contains("*"))
            XCTAssertTrue(configuration.resolvedMethodNames.contains("testMethod1()"))
            XCTAssertTrue(configuration.resolvedMethodNames.contains("testMethod2(_:)"))
        } catch {
            XCTFail("Failed to apply configuration for \(conf3)")
        }
    }

    func testModifierOrderConfigurationFromDictionary() throws {
        var configuration = ModifierOrderConfiguration()
        let config: [String: Any] = [
            "severity": "warning",
            "preferred_modifier_order": [
                "override",
                "acl",
                "setterACL",
                "owned",
                "mutators",
                "final",
                "typeMethods",
                "required",
                "convenience",
                "lazy",
                "dynamic",
            ],
        ]

        try configuration.apply(configuration: config)
        let expected: [SwiftDeclarationAttributeKind.ModifierGroup] = [
            .override,
            .acl,
            .setterACL,
            .owned,
            .mutators,
            .final,
            .typeMethods,
            .required,
            .convenience,
            .lazy,
            .dynamic,
        ]
        XCTAssertEqual(configuration.severityConfiguration.severity, .warning)
        XCTAssertEqual(configuration.preferredModifierOrder, expected)
    }

    func testModifierOrderConfigurationThrowsOnUnrecognizedModifierGroup() {
        var configuration = ModifierOrderConfiguration()
        let config = ["severity": "warning", "preferred_modifier_order": ["specialize"]]  as [String: any Sendable]

        checkError(Issue.invalidConfiguration(ruleID: ModifierOrderRule.identifier)) {
            try configuration.apply(configuration: config)
        }
    }

    func testModifierOrderConfigurationThrowsOnNonModifiableGroup() {
        var configuration = ModifierOrderConfiguration()
        let config = ["severity": "warning", "preferred_modifier_order": ["atPrefixed"]]  as [String: any Sendable]
        checkError(Issue.invalidConfiguration(ruleID: ModifierOrderRule.identifier)) {
            try configuration.apply(configuration: config)
        }
    }

    func testComputedAccessorsOrderRuleConfiguration() throws {
        var configuration = ComputedAccessorsOrderConfiguration()
        let config = ["severity": "error", "order": "set_get"]
        try configuration.apply(configuration: config)

        XCTAssertEqual(configuration.severityConfiguration.severity, .error)
        XCTAssertEqual(configuration.order, .setGet)

        XCTAssertEqual(
            RuleConfigurationDescription.from(configuration: configuration).oneLiner(),
            "severity: error; order: set_get")
    }
}
