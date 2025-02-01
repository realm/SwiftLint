import SourceKittenFramework
import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules
@testable import SwiftLintCore

@Suite
struct RuleConfigurationTests {
    private let defaultNestingConfiguration = NestingConfiguration(
        typeLevel: SeverityLevelsConfiguration(warning: 0),
        functionLevel: SeverityLevelsConfiguration(warning: 0)
    )

    @Test
    func nestingConfigurationSetsCorrectly() {
        let config =
            [
                "type_level": [
                    "warning": 7, "error": 17,
                ],
                "function_level": [
                    "warning": 8, "error": 18,
                ],
                "check_nesting_in_closures_and_statements": false,
                "always_allow_one_type_in_functions": true,
            ] as [String: any Sendable]
        var nestingConfig = defaultNestingConfiguration
        do {
            try nestingConfig.apply(configuration: config)
            #expect(nestingConfig.typeLevel.warning == 7)
            #expect(nestingConfig.functionLevel.warning == 8)
            #expect(nestingConfig.typeLevel.error == 17)
            #expect(nestingConfig.functionLevel.error == 18)
            #expect(nestingConfig.alwaysAllowOneTypeInFunctions)
            #expect(!nestingConfig.checkNestingInClosuresAndStatements)
        } catch {
            Issue.record("Failed to configure nested configurations")
        }
    }

    @Test
    func nestingConfigurationThrowsOnBadConfig() {
        let config = 17
        var nestingConfig = defaultNestingConfiguration
        #expect(throws: Issue.invalidConfiguration(ruleID: NestingRule.identifier)) {
            try nestingConfig.apply(configuration: config)
        }
    }

    @Test
    func severityWorksAsOnlyParameter() throws {
        var config = AttributesConfiguration()
        #expect(config.severity == .warning)
        try config.apply(configuration: "error")
        #expect(config.severity == .error)
    }

    @Test
    func severityConfigurationFromString() {
        let config = "Warning"
        let comp = SeverityConfiguration<RuleMock>(.warning)
        var severityConfig = SeverityConfiguration<RuleMock>(.error)
        #expect(throws: Never.self) {
            try severityConfig.apply(configuration: config)
        }
        #expect(severityConfig == comp)
    }

    @Test
    func severityConfigurationFromDictionary() {
        let config = ["severity": "warning"]
        let comp = SeverityConfiguration<RuleMock>(.warning)
        var severityConfig = SeverityConfiguration<RuleMock>(.error)
        do {
            try severityConfig.apply(configuration: config)
            #expect(severityConfig == comp)
        } catch {
            Issue.record("Failed to configure severity from dictionary")
        }
    }

    @Test
    func severityConfigurationThrowsNothingApplied() throws {
        let config = 17
        var severityConfig = SeverityConfiguration<RuleMock>(.error)
        #expect(throws: Issue.nothingApplied(ruleID: RuleMock.identifier)) {
            try severityConfig.apply(configuration: config)
        }
    }

    @Test
    func severityConfigurationThrowsInvalidConfiguration() {
        let config = "foo"
        var severityConfig = SeverityConfiguration<RuleMock>(.warning)
        #expect(throws: Issue.invalidConfiguration(ruleID: RuleMock.identifier)) {
            try severityConfig.apply(configuration: config)
        }
    }

    @Test
    func severityLevelConfigParams() {
        let severityConfig = SeverityLevelsConfiguration<RuleMock>(warning: 17, error: 7)
        #expect(
            severityConfig.params == [
                RuleParameter(severity: .error, value: 7),
                RuleParameter(severity: .warning, value: 17),
            ]
        )
    }

    @Test
    func severityLevelConfigPartialParams() {
        let severityConfig = SeverityLevelsConfiguration<RuleMock>(warning: 17, error: nil)
        #expect(severityConfig.params == [RuleParameter(severity: .warning, value: 17)])
    }

    @Test
    func severityLevelConfigApplyNilErrorValue() throws {
        var severityConfig = SeverityLevelsConfiguration<RuleMock>(warning: 17, error: 20)
        try severityConfig.apply(configuration: ["error": nil, "warning": 18])
        #expect(severityConfig.params == [RuleParameter(severity: .warning, value: 18)])
    }

    @Test
    func severityLevelConfigApplyMissingErrorValue() throws {
        var severityConfig = SeverityLevelsConfiguration<RuleMock>(warning: 17, error: 20)
        try severityConfig.apply(configuration: ["warning": 18])
        #expect(severityConfig.params == [RuleParameter(severity: .warning, value: 18)])
    }

    @Test
    func regexConfigurationThrows() {
        let config = 17
        var regexConfig = RegexConfiguration<RuleMock>(identifier: "")
        #expect(throws: Issue.invalidConfiguration(ruleID: RuleMock.identifier)) {
            try regexConfig.apply(configuration: config)
        }
    }

    @Test
    func regexRuleDescription() {
        var regexConfig = RegexConfiguration<RuleMock>(identifier: "regex")
        #expect(
            regexConfig.description
                == RuleDescription(
                    identifier: "regex",
                    name: "regex",
                    description: "", kind: .style))
        regexConfig.name = "name"
        #expect(
            regexConfig.description
                == RuleDescription(
                    identifier: "regex",
                    name: "name",
                    description: "", kind: .style))
    }

    @Test
    func trailingWhitespaceConfigurationThrowsOnBadConfig() {
        let config = "unknown"
        var configuration = TrailingWhitespaceConfiguration(
            ignoresEmptyLines: false,
            ignoresComments: true)
        #expect(throws: Issue.invalidConfiguration(ruleID: TrailingWhitespaceRule.identifier)) {
            try configuration.apply(configuration: config)
        }
    }

    @Test
    func trailingWhitespaceConfigurationInitializerSetsIgnoresEmptyLines() {
        let configuration1 = TrailingWhitespaceConfiguration(
            ignoresEmptyLines: false,
            ignoresComments: true)
        #expect(!configuration1.ignoresEmptyLines)

        let configuration2 = TrailingWhitespaceConfiguration(
            ignoresEmptyLines: true,
            ignoresComments: true)
        #expect(configuration2.ignoresEmptyLines)
    }

    @Test
    func trailingWhitespaceConfigurationInitializerSetsIgnoresComments() {
        let configuration1 = TrailingWhitespaceConfiguration(
            ignoresEmptyLines: false,
            ignoresComments: true)
        #expect(configuration1.ignoresComments)

        let configuration2 = TrailingWhitespaceConfiguration(
            ignoresEmptyLines: false,
            ignoresComments: false)
        #expect(!configuration2.ignoresComments)
    }

    @Test
    func trailingWhitespaceConfigurationApplyConfigurationSetsIgnoresEmptyLines() {
        var configuration = TrailingWhitespaceConfiguration(
            ignoresEmptyLines: false,
            ignoresComments: true
        )
        let config1 = ["ignores_empty_lines": true]
        #expect(throws: Never.self) {
            try configuration.apply(configuration: config1)
        }
        #expect(configuration.ignoresEmptyLines)

        let config2 = ["ignores_empty_lines": false]
        #expect(throws: Never.self) {
            try configuration.apply(configuration: config2)
        }
        #expect(!configuration.ignoresEmptyLines)
    }

    @Test
    func trailingWhitespaceConfigurationApplyConfigurationSetsIgnoresComments() {
        var configuration = TrailingWhitespaceConfiguration(
            ignoresEmptyLines: false,
            ignoresComments: true
        )
        let config1 = ["ignores_comments": true]
        #expect(throws: Never.self) {
            try configuration.apply(configuration: config1)
        }
        #expect(configuration.ignoresComments)

        let config2 = ["ignores_comments": false]
        #expect(throws: Never.self) {
            try configuration.apply(configuration: config2)
        }
        #expect(!configuration.ignoresComments)
    }

    @Test
    func trailingWhitespaceConfigurationCompares() {
        let configuration1 = TrailingWhitespaceConfiguration(
            ignoresEmptyLines: false,
            ignoresComments: true)
        let configuration2 = TrailingWhitespaceConfiguration(
            ignoresEmptyLines: true,
            ignoresComments: true)
        #expect(configuration1 != configuration2)

        let configuration3 = TrailingWhitespaceConfiguration(
            ignoresEmptyLines: true,
            ignoresComments: true)
        #expect(configuration2 == configuration3)

        let configuration4 = TrailingWhitespaceConfiguration(
            ignoresEmptyLines: false,
            ignoresComments: false)

        #expect(configuration1 != configuration4)

        let configuration5 = TrailingWhitespaceConfiguration(
            ignoresEmptyLines: true,
            ignoresComments: false)

        #expect(configuration1 != configuration5)
    }

    @Test
    func trailingWhitespaceConfigurationApplyConfigurationUpdatesSeverityConfiguration() {
        var configuration = TrailingWhitespaceConfiguration(
            severityConfiguration: .warning,
            ignoresEmptyLines: false,
            ignoresComments: true
        )

        #expect(throws: Never.self) {
            try configuration.apply(configuration: ["severity": "error"])
        }
        #expect(configuration.severityConfiguration.severity == .error)
    }

    @Test
    func overriddenSuperCallConfigurationFromDictionary() {
        var configuration = OverriddenSuperCallConfiguration()
        #expect(configuration.resolvedMethodNames.contains("viewWillAppear(_:)"))

        let conf1 = ["severity": "error", "excluded": "viewWillAppear(_:)"]
        #expect(throws: Never.self) {
            try configuration.apply(configuration: conf1)
        }
        #expect(configuration.severityConfiguration.severity == .error)
        #expect(!configuration.resolvedMethodNames.contains("*"))
        #expect(!configuration.resolvedMethodNames.contains("viewWillAppear(_:)"))
        #expect(configuration.resolvedMethodNames.contains("viewWillDisappear(_:)"))

        let conf2 = [
            "severity": "error",
            "excluded": "viewWillAppear(_:)",
            "included": ["*", "testMethod1()", "testMethod2(_:)"],
        ] as [String: any Sendable]
        #expect(throws: Never.self) {
            try configuration.apply(configuration: conf2)
        }
        #expect(configuration.severityConfiguration.severity == .error)
        #expect(!configuration.resolvedMethodNames.contains("*"))
        #expect(!configuration.resolvedMethodNames.contains("viewWillAppear(_:)"))
        #expect(configuration.resolvedMethodNames.contains("viewWillDisappear(_:)"))
        #expect(configuration.resolvedMethodNames.contains("testMethod1()"))
        #expect(configuration.resolvedMethodNames.contains("testMethod2(_:)"))

        let conf3 = [
            "severity": "warning",
            "excluded": "*",
            "included": ["testMethod1()", "testMethod2(_:)"],
        ] as [String: any Sendable]
        #expect(throws: Never.self) {
            try configuration.apply(configuration: conf3)
        }
        #expect(configuration.severityConfiguration.severity == .warning)
        #expect(configuration.resolvedMethodNames.count == 2)
        #expect(!configuration.resolvedMethodNames.contains("*"))
        #expect(configuration.resolvedMethodNames.contains("testMethod1()"))
        #expect(configuration.resolvedMethodNames.contains("testMethod2(_:)"))
    }

    @Test
    func modifierOrderConfigurationFromDictionary() throws {
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
        #expect(configuration.severityConfiguration.severity == .warning)
        #expect(configuration.preferredModifierOrder == expected)
    }

    @Test
    func modifierOrderConfigurationThrowsOnUnrecognizedModifierGroup() {
        var configuration = ModifierOrderConfiguration()
        let config =
            ["severity": "warning", "preferred_modifier_order": ["specialize"]]
            as [String: any Sendable]

        #expect(throws: Issue.invalidConfiguration(ruleID: ModifierOrderRule.identifier)) {
            try configuration.apply(configuration: config)
        }
    }

    @Test
    func modifierOrderConfigurationThrowsOnNonModifiableGroup() {
        var configuration = ModifierOrderConfiguration()
        let config = ["severity": "warning", "preferred_modifier_order": ["atPrefixed"]] as [String: any Sendable]
        #expect(throws: Issue.invalidConfiguration(ruleID: ModifierOrderRule.identifier)) {
            try configuration.apply(configuration: config)
        }
    }

    @Test
    func computedAccessorsOrderRuleConfiguration() throws {
        var configuration = ComputedAccessorsOrderConfiguration()
        let config = ["severity": "error", "order": "set_get"]
        try configuration.apply(configuration: config)

        #expect(configuration.severityConfiguration.severity == .error)
        #expect(configuration.order == .setGet)

        #expect(
            RuleConfigurationDescription.from(configuration: configuration).oneLiner()
                == "severity: error; order: set_get")
    }
}
