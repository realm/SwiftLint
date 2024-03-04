@testable import SwiftLintBuiltInRules
@testable import SwiftLintFramework
import XCTest

// swiftlint:disable file_length

private extension Configuration {
    func contains<T: Rule>(rule _: T.Type) -> Bool {
        rules.contains { $0 is T }
    }
}

extension ConfigurationTests {
    // MARK: - Rules Merging
    func testMerge() {
        let config0Merge2 = Mock.Config._0.merged(withChild: Mock.Config._2)

        XCTAssertFalse(Mock.Config._0.contains(rule: ForceCastRule.self))
        XCTAssertTrue(Mock.Config._2.contains(rule: ForceCastRule.self))
        XCTAssertFalse(config0Merge2.contains(rule: ForceCastRule.self))

        XCTAssertTrue(Mock.Config._0.contains(rule: TodoRule.self))
        XCTAssertTrue(Mock.Config._2.contains(rule: TodoRule.self))
        XCTAssertTrue(config0Merge2.contains(rule: TodoRule.self))

        XCTAssertFalse(Mock.Config._3.contains(rule: TodoRule.self))
        XCTAssertFalse(
            config0Merge2.merged(withChild: Mock.Config._3).contains(rule: TodoRule.self)
        )
    }

    // MARK: - Merging Aspects
    func testWarningThresholdMerging() {
        func configuration(forWarningThreshold warningThreshold: Int?) -> Configuration {
            Configuration(
                warningThreshold: warningThreshold,
                reporter: XcodeReporter.identifier
            )
        }
        XCTAssertEqual(configuration(forWarningThreshold: 3)
            .merged(withChild: configuration(forWarningThreshold: 2)).warningThreshold,
                       2)
        XCTAssertEqual(configuration(forWarningThreshold: nil)
            .merged(withChild: configuration(forWarningThreshold: 2)).warningThreshold,
                       2)
        XCTAssertEqual(configuration(forWarningThreshold: 3)
            .merged(withChild: configuration(forWarningThreshold: nil)).warningThreshold,
                       3)
        XCTAssertNil(configuration(forWarningThreshold: nil)
            .merged(withChild: configuration(forWarningThreshold: nil)).warningThreshold)
    }

    func testOnlyRulesMerging() {
        let baseConfiguration = Configuration(
            rulesMode: .defaultConfiguration(
                disabled: [],
                optIn: [
                    ForceTryRule.identifier,
                    ForceCastRule.identifier,
                ]
            )
        )
        let onlyConfiguration = Configuration(rulesMode: .onlyConfiguration([TodoRule.identifier]))
        XCTAssertTrue(baseConfiguration.contains(rule: TodoRule.self))
        XCTAssertEqual(onlyConfiguration.rules.count, 1)
        XCTAssertTrue(onlyConfiguration.rules[0] is TodoRule)

        let mergedConfiguration1 = baseConfiguration.merged(withChild: onlyConfiguration)
        XCTAssertEqual(mergedConfiguration1.rules.count, 1)
        XCTAssertTrue(mergedConfiguration1.rules[0] is TodoRule)

        // Also test the other way around
        let mergedConfiguration2 = onlyConfiguration.merged(withChild: baseConfiguration)
        XCTAssertEqual(mergedConfiguration2.rules.count, 3) // 2 opt-ins + 1 from the only rules
        XCTAssertTrue(mergedConfiguration2.contains(rule: TodoRule.self))
        XCTAssertTrue(mergedConfiguration2.contains(rule: ForceCastRule.self))
        XCTAssertTrue(mergedConfiguration2.contains(rule: ForceTryRule.self))
    }

    func testOnlyRuleMerging() {
        let ruleIdentifier = TodoRule.identifier
        let onlyRuleConfiguration = Configuration.onlyRuleConfiguration(ruleIdentifier)

        let emptyDefaultConfiguration = Configuration.emptyDefaultConfiguration()
        let mergedConfiguration1 = onlyRuleConfiguration.merged(withChild: emptyDefaultConfiguration)
        XCTAssertEqual(mergedConfiguration1.rules.count, 1)
        XCTAssertTrue(mergedConfiguration1.rules[0] is TodoRule)

        let disabledDefaultConfiguration = Configuration.disabledDefaultConfiguration(ruleIdentifier)
        let mergedConfiguration2 = onlyRuleConfiguration.merged(withChild: disabledDefaultConfiguration)
        XCTAssertTrue(mergedConfiguration2.rules.isEmpty)

        let enabledOnlyConfiguration = Configuration.enabledOnlyConfiguration(ForceTryRule.identifier)
        let mergedConfiguration3 = onlyRuleConfiguration.merged(withChild: enabledOnlyConfiguration)
        XCTAssertEqual(mergedConfiguration3.rules.count, 1)
        XCTAssertTrue(mergedConfiguration3.rules[0] is TodoRule)
    }

    func testCustomRulesMerging() {
        let mergedConfiguration = Mock.Config._0CustomRules.merged(
            withChild: Mock.Config._2CustomRules,
            rootDirectory: ""
        )
        guard let mergedCustomRules = mergedConfiguration.rules.first(where: { $0 is CustomRules }) as? CustomRules
            else {
            XCTFail("Custom rules are expected to be present")
            return
        }
        XCTAssertTrue(
            mergedCustomRules.configuration.customRuleConfigurations.contains { $0.identifier == "no_abc" }
        )
        XCTAssertTrue(
            mergedCustomRules.configuration.customRuleConfigurations.contains { $0.identifier == "no_abcd" }
        )
    }

    func testMergingAllowsDisablingParentsCustomRules() {
        let mergedConfiguration = Mock.Config._0CustomRules.merged(
            withChild: Mock.Config._2CustomRulesDisabled,
            rootDirectory: ""
        )
        guard let mergedCustomRules = mergedConfiguration.rules.first(where: { $0 is CustomRules }) as? CustomRules
            else {
            XCTFail("Custom rules are expected to be present")
            return
        }
        XCTAssertFalse(
            mergedCustomRules.configuration.customRuleConfigurations.contains { $0.identifier == "no_abc" }
        )
        XCTAssertTrue(
            mergedCustomRules.configuration.customRuleConfigurations.contains { $0.identifier == "no_abcd" }
        )
    }

    func testCustomRulesMergingWithOnlyRulesCase1() {
        // The base configuration is in only rules mode
        // The child configuration is in the default rules mode
        // => all custom rules should be considered
        let mergedConfiguration = Mock.Config._0CustomRulesOnly.merged(
            withChild: Mock.Config._2CustomRules,
            rootDirectory: ""
        )
        guard let mergedCustomRules = mergedConfiguration.rules.first(where: { $0 is CustomRules }) as? CustomRules
            else {
            XCTFail("Custom rules are expected to be present")
            return
        }
        XCTAssertTrue(
            mergedCustomRules.configuration.customRuleConfigurations.contains { $0.identifier == "no_abc" }
        )
        XCTAssertTrue(
            mergedCustomRules.configuration.customRuleConfigurations.contains { $0.identifier == "no_abcd" }
        )
    }

    func testCustomRulesMergingWithOnlyRulesCase2() {
        // The base configuration is in only rules mode
        // The child configuration is in the only rules mode
        // => only the custom rules from the child configuration should be considered
        // (because custom rules from base configuration would require explicit mention as one of the `only_rules`)
        let mergedConfiguration = Mock.Config._0CustomRulesOnly.merged(
            withChild: Mock.Config._2CustomRulesOnly,
            rootDirectory: ""
        )
        guard let mergedCustomRules = mergedConfiguration.rules.first(where: { $0 is CustomRules }) as? CustomRules
            else {
            XCTFail("Custom rules are expected to be present")
            return
        }
        XCTAssertFalse(
            mergedCustomRules.configuration.customRuleConfigurations.contains { $0.identifier == "no_abc" }
        )
        XCTAssertTrue(
            mergedCustomRules.configuration.customRuleConfigurations.contains { $0.identifier == "no_abcd" }
        )
    }

    func testCustomRulesReconfiguration() {
        // Custom Rule severity gets reconfigured to "error"
        let mergedConfiguration = Mock.Config._0CustomRulesOnly.merged(
            withChild: Mock.Config._2CustomRulesReconfig,
            rootDirectory: ""
        )
        guard let mergedCustomRules = mergedConfiguration.rules.first(where: { $0 is CustomRules }) as? CustomRules
            else {
            XCTFail("Custom rules are expected to be present")
            return
        }
        XCTAssertEqual(
            mergedCustomRules.configuration.customRuleConfigurations.filter { $0.identifier == "no_abc" }.count, 1
        )
        guard let customRule = (mergedCustomRules.configuration.customRuleConfigurations.first {
            $0.identifier == "no_abc"
        }) else {
            XCTFail("Custom rule is expected to be present")
            return
        }
        XCTAssertEqual(customRule.severityConfiguration.severity, .error)
    }

    // MARK: - Nested Configurations
    func testLevel0() {
        XCTAssertEqual(Mock.Config._0.configuration(for: SwiftLintFile(path: Mock.Swift._0)!),
                       Mock.Config._0)
    }

    func testLevel1() {
        XCTAssertEqual(Mock.Config._0.configuration(for: SwiftLintFile(path: Mock.Swift._1)!),
                       Mock.Config._0)
    }

    func testLevel2() {
        let config = Mock.Config._0.configuration(for: SwiftLintFile(path: Mock.Swift._2)!)
        var config2 = Mock.Config._2
        config2.fileGraph = Configuration.FileGraph(rootDirectory: Mock.Dir.level2)

        XCTAssertEqual(
            config,
            Mock.Config._0.merged(withChild: config2, rootDirectory: config.rootDirectory)
        )
    }

    func testLevel3() {
        let config = Mock.Config._0.configuration(for: SwiftLintFile(path: Mock.Swift._3)!)
        var config3 = Mock.Config._3
        config3.fileGraph = Configuration.FileGraph(rootDirectory: Mock.Dir.level3)

        XCTAssertEqual(
            config,
            Mock.Config._0.merged(withChild: config3, rootDirectory: config.rootDirectory)
        )
    }

    func testNestedConfigurationForOnePathPassedIn() {
        // If a path to one or more configuration files is specified, nested configurations should be ignored
        let config = Configuration(configurationFiles: [Mock.Yml._0])
        XCTAssertEqual(
            config.configuration(for: SwiftLintFile(path: Mock.Swift._3)!),
            config
        )
    }

    func testParentConfigIsIgnoredAsNestedConfiguration() {
        // If a configuration has already been used to build the main config,
        // it should not again be regarded as a nested config
        XCTAssertEqual(
            Mock.Config.nested.configuration(for: SwiftLintFile(path: Mock.Swift.nestedSub)!),
            Mock.Config.nested
        )
    }

    // MARK: - Child & Parent Configs
    func testValidChildConfig() {
        guard !isRunningWithBazel else {
            return
        }

        for path in [Mock.Dir.childConfigTest1, Mock.Dir.childConfigTest2] {
            XCTAssert(FileManager.default.changeCurrentDirectoryPath(path))

            assertEqualExceptForFileGraph(
                Configuration(configurationFiles: ["main.yml"]),
                Configuration(configurationFiles: ["expected.yml"])
            )
        }
    }

    func testValidParentConfig() {
        for path in [Mock.Dir.parentConfigTest1, Mock.Dir.parentConfigTest2] {
            XCTAssert(FileManager.default.changeCurrentDirectoryPath(path))

            assertEqualExceptForFileGraph(
                Configuration(configurationFiles: ["main.yml"]),
                Configuration(configurationFiles: ["expected.yml"])
            )
        }
    }

    func testCommandLineChildConfigs() {
        guard !isRunningWithBazel else {
            return
        }

        for path in [Mock.Dir.childConfigTest1, Mock.Dir.childConfigTest2] {
            XCTAssert(FileManager.default.changeCurrentDirectoryPath(path))

            assertEqualExceptForFileGraph(
                Configuration(
                    configurationFiles: ["main.yml", "child1.yml", "child2.yml"]
                ),
                Configuration(configurationFiles: ["expected.yml"])
            )
        }
    }

    func testConfigCycleDetection() {
        for path in [
            Mock.Dir.childConfigCycle1,
            Mock.Dir.childConfigCycle2,
            Mock.Dir.childConfigCycle3,
            Mock.Dir.parentConfigCycle1,
            Mock.Dir.parentConfigCycle2,
            Mock.Dir.parentConfigCycle3,
        ] {
            XCTAssert(FileManager.default.changeCurrentDirectoryPath(path))

            // If the cycle is properly detected, the config should equal the default config.
            XCTAssertEqual(
                Configuration(configurationFiles: []), // not specifying a file means the .swiftlint.yml will be used
                Configuration()
            )
        }
    }

    func testCommandLineConfigsCycleDetection() {
        XCTAssert(FileManager.default.changeCurrentDirectoryPath(Mock.Dir.childConfigCycle4))

        // If the cycle is properly detected, the config should equal the default config.
        assertEqualExceptForFileGraph(
            Configuration(
                configurationFiles: ["main.yml", "child.yml"],
                useDefaultConfigOnFailure: true
            ),
            Configuration()
        )
    }

    func testParentChildOptInAndDisable() {
        struct TestCase: Equatable {
            let optedInInParent: Bool
            let disabledInParent: Bool
            let optedInInChild: Bool
            let disabledInChild: Bool
            let isEnabled: Bool
            var message: String {
                "optedInInParent = \(optedInInParent) " +
                "disabledInParent = \(disabledInParent) " +
                "optedInInChild = \(optedInInChild) " +
                "disabledInChild = \(disabledInChild)"
            }
        }
        let testCases: [TestCase] = [
            // swiftlint:disable line_length
            TestCase(optedInInParent: false, disabledInParent: false, optedInInChild: false, disabledInChild: false, isEnabled: false),
            TestCase(optedInInParent: true, disabledInParent: false, optedInInChild: false, disabledInChild: false, isEnabled: true),
            TestCase(optedInInParent: false, disabledInParent: true, optedInInChild: false, disabledInChild: false, isEnabled: false),
            TestCase(optedInInParent: true, disabledInParent: true, optedInInChild: false, disabledInChild: false, isEnabled: false),
            TestCase(optedInInParent: false, disabledInParent: false, optedInInChild: true, disabledInChild: false, isEnabled: true),
            TestCase(optedInInParent: true, disabledInParent: false, optedInInChild: true, disabledInChild: false, isEnabled: true),
            TestCase(optedInInParent: false, disabledInParent: true, optedInInChild: true, disabledInChild: false, isEnabled: true),
            TestCase(optedInInParent: true, disabledInParent: true, optedInInChild: true, disabledInChild: false, isEnabled: true),
            TestCase(optedInInParent: false, disabledInParent: false, optedInInChild: false, disabledInChild: true, isEnabled: false),
            TestCase(optedInInParent: true, disabledInParent: false, optedInInChild: false, disabledInChild: true, isEnabled: false),
            TestCase(optedInInParent: false, disabledInParent: true, optedInInChild: false, disabledInChild: true, isEnabled: false),
            TestCase(optedInInParent: true, disabledInParent: true, optedInInChild: false, disabledInChild: true, isEnabled: false),
            TestCase(optedInInParent: false, disabledInParent: false, optedInInChild: true, disabledInChild: true, isEnabled: false),
            TestCase(optedInInParent: true, disabledInParent: false, optedInInChild: true, disabledInChild: true, isEnabled: false),
            TestCase(optedInInParent: false, disabledInParent: true, optedInInChild: true, disabledInChild: true, isEnabled: false),
            TestCase(optedInInParent: true, disabledInParent: true, optedInInChild: true, disabledInChild: true, isEnabled: false),
            // swiftlint:enable line_length
        ]
        XCTAssertEqual(testCases.unique.count, 4 * 4)
        let ruleType = ImplicitReturnRule.self
        XCTAssertTrue((ruleType as Any) is any OptInRule.Type)
        let ruleIdentifier = ruleType.identifier
        for testCase in testCases {
            let parentConfiguration = Configuration(rulesMode: .defaultConfiguration(
                disabled: testCase.disabledInParent ? [ruleIdentifier] : [],
                optIn: testCase.optedInInParent ? [ruleIdentifier] : []
            ))
            let childConfiguration = Configuration(rulesMode: .defaultConfiguration(
                disabled: testCase.disabledInChild ? [ruleIdentifier] : [],
                optIn: testCase.optedInInChild ? [ruleIdentifier] : []
            ))
            let mergedConfiguration = parentConfiguration.merged(withChild: childConfiguration)
            let isEnabled = mergedConfiguration.contains(rule: ruleType)
            XCTAssertEqual(isEnabled, testCase.isEnabled, testCase.message)
        }
    }

    func testParentChildDisableForDefaultRule() {
        struct TestCase: Equatable {
            let disabledInParent: Bool
            let disabledInChild: Bool
            let isEnabled: Bool
            var message: String {
                "disabledInParent = \(disabledInParent) disabledInChild = \(disabledInChild)"
            }
        }
        let testCases: [TestCase] = [
            TestCase(disabledInParent: false, disabledInChild: false, isEnabled: true),
            TestCase(disabledInParent: true, disabledInChild: false, isEnabled: false),
            TestCase(disabledInParent: false, disabledInChild: true, isEnabled: false),
            TestCase(disabledInParent: true, disabledInChild: true, isEnabled: false),
        ]
        XCTAssertEqual(testCases.unique.count, 2 * 2)
        let ruleType = BlanketDisableCommandRule.self
        XCTAssertFalse(ruleType is any OptInRule.Type)
        let ruleIdentifier = ruleType.identifier
        for testCase in testCases {
            let parentConfiguration = Configuration(
                rulesMode: .defaultConfiguration(disabled: testCase.disabledInParent ? [ruleIdentifier] : [], optIn: [])
            )
            let childConfiguration = Configuration(
                rulesMode: .defaultConfiguration(disabled: testCase.disabledInChild ? [ruleIdentifier] : [], optIn: [])
            )
            let mergedConfiguration = parentConfiguration.merged(withChild: childConfiguration)
            let isEnabled = mergedConfiguration.contains(rule: ruleType)
            XCTAssertEqual(isEnabled, testCase.isEnabled, testCase.message)
        }
    }

    func testParentOnlyRulesAndChildOptInAndDisabled() {
        struct TestCase: Equatable {
            let optedInInChild: Bool
            let disabledInChild: Bool
            let isEnabled: Bool
            var message: String {
                "optedInInChild = \(optedInInChild) disabledInChild = \(disabledInChild)"
            }
        }
        let testCases: [TestCase] = [
            TestCase(optedInInChild: false, disabledInChild: false, isEnabled: true),
            TestCase(optedInInChild: true, disabledInChild: false, isEnabled: true),
            TestCase(optedInInChild: false, disabledInChild: true, isEnabled: false),
            TestCase(optedInInChild: true, disabledInChild: true, isEnabled: false),
        ]
        XCTAssertEqual(testCases.unique.count, 2 * 2)
        let ruleType = ImplicitReturnRule.self
        XCTAssertTrue((ruleType as Any) is any OptInRule.Type)
        let ruleIdentifier = ruleType.identifier
        let parentConfiguration = Configuration(rulesMode: .onlyConfiguration([ruleIdentifier]))
        for testCase in testCases {
            let childConfiguration = Configuration(rulesMode: .defaultConfiguration(
                disabled: testCase.disabledInChild ? [ruleIdentifier] : [],
                optIn: testCase.optedInInChild ? [ruleIdentifier] : []
            ))
            let mergedConfiguration = parentConfiguration.merged(withChild: childConfiguration)
            let isEnabled = mergedConfiguration.contains(rule: ruleType)
            XCTAssertEqual(isEnabled, testCase.isEnabled, testCase.message)
        }
    }

    // MARK: Warnings about configurations for disabled rules
    func testDefaultConfigurationDisabledRuleWarnings() {
        let optInRuleType = ImplicitReturnRule.self
        XCTAssertTrue((optInRuleType as Any) is any OptInRule.Type)
        testDefaultConfigurationDisabledRuleWarnings(for: optInRuleType)

        let defaultRuleType = BlockBasedKVORule.self
        XCTAssertFalse((defaultRuleType as Any) is any OptInRule.Type)
        testDefaultConfigurationDisabledRuleWarnings(for: defaultRuleType)
    }

    private func testDefaultConfigurationDisabledRuleWarnings(for ruleType: any Rule.Type) {
        let ruleIdentifier = ruleType.identifier

        let parentConfigurations = [
            nil,
            Configuration.emptyDefaultConfiguration(),
            Configuration.optInDefaultConfiguration(ruleIdentifier),
            Configuration.optInDisabledDefaultConfiguration(ruleIdentifier),
            Configuration.disabledDefaultConfiguration(ruleIdentifier),
            Configuration.emptyOnlyConfiguration(),
            Configuration.enabledOnlyConfiguration(ruleIdentifier),
            Configuration.allEnabledConfiguration(),
        ]

        let configurations = [
            Configuration(rulesMode: .defaultConfiguration(disabled: [], optIn: [])),
            Configuration(rulesMode: .defaultConfiguration(disabled: [], optIn: [ruleIdentifier])),
            Configuration(rulesMode: .defaultConfiguration(disabled: [ruleIdentifier], optIn: [ruleIdentifier])),
            Configuration(rulesMode: .defaultConfiguration(disabled: [ruleIdentifier], optIn: [])),
        ]

        for parentConfiguration in parentConfigurations {
            for configuration in configurations {
                testParentConfiguration(parentConfiguration, configuration: configuration, ruleType: ruleType)
            }
        }
    }

    private func testParentConfiguration(
        _ parentConfiguration: Configuration?,
        configuration: Configuration,
        ruleType: any Rule.Type
    ) {
        guard case .defaultConfiguration(let disabledRules, let optInRules) = configuration.rulesMode else {
            XCTFail("Configuration rulesMode was not the default")
            return
        }

        let mergedConfiguration = parentConfiguration?.merged(withChild: configuration) ?? configuration
        let isEnabled = mergedConfiguration.contains(rule: ruleType)
        let issue = Configuration.validateConfiguredRuleIsEnabled(
            parentConfiguration: parentConfiguration,
            disabledRules: disabledRules,
            optInRules: optInRules,
            ruleType: ruleType
        )
        XCTAssertEqual(isEnabled, issue == nil)
        guard let issue else {
            return
        }
        let ruleIdentifier = ruleType.identifier

        guard disabledRules.isEmpty, optInRules.isEmpty else {
            XCTAssertEqual(issue, Issue.ruleDisabledInDisabledRules(ruleID: ruleIdentifier))
            return
        }

        if parentConfiguration == nil ||
            parentConfiguration == Configuration.emptyDefaultConfiguration() {
            XCTAssertEqual(issue, Issue.ruleNotEnabledInOptInRules(ruleID: ruleIdentifier))
        } else if parentConfiguration == Configuration.emptyOnlyConfiguration() {
            if ruleType is any OptInRule.Type {
                XCTAssertEqual(issue, Issue.ruleNotEnabledInOptInRules(ruleID: ruleIdentifier))
            } else {
                XCTAssertEqual(issue, Issue.ruleNotEnabledInParentOnlyRules(ruleID: ruleIdentifier))
            }
        } else if parentConfiguration == Configuration.optInDisabledDefaultConfiguration(ruleIdentifier) ||
            parentConfiguration == Configuration.disabledDefaultConfiguration(ruleIdentifier) {
            XCTAssertEqual(issue, Issue.ruleDisabledInParentConfiguration(ruleID: ruleIdentifier))
        }
    }

    func testOnlyConfigurationDisabledRulesWarnings() {
        let optInRuleType = ImplicitReturnRule.self
        XCTAssertTrue((optInRuleType as Any) is any OptInRule.Type)
        testOnlyConfigurationDisabledRulesWarnings(ruleType: optInRuleType)

        let defaultRuleType = BlockBasedKVORule.self
        XCTAssertFalse((defaultRuleType as Any) is any OptInRule.Type)
        testOnlyConfigurationDisabledRulesWarnings(ruleType: defaultRuleType)
    }

    private func testOnlyConfigurationDisabledRulesWarnings(ruleType: any Rule.Type) {
        let issue = Configuration.validateConfiguredRuleIsEnabled(onlyRules: [], ruleType: ruleType)
        XCTAssertEqual(issue, Issue.ruleNotPresentInOnlyRules(ruleID: ruleType.identifier))
        XCTAssertNil(
            Configuration.validateConfiguredRuleIsEnabled(onlyRules: [ruleType.identifier], ruleType: ruleType)
        )
    }

    // MARK: - Remote Configs
    func testValidRemoteChildConfig() {
        XCTAssert(FileManager.default.changeCurrentDirectoryPath(Mock.Dir.remoteConfigChild))

        assertEqualExceptForFileGraph(
            Configuration(
                configurationFiles: ["main.yml"],
                mockedNetworkResults: [
                    "https://www.mock.com":
                    """
                    included:
                      - Test/Test1/Test/Test
                      - Test/Test2/Test/Test
                    """,
                ]
            ),
            Configuration(configurationFiles: ["expected.yml"])
        )
    }

    func testValidRemoteParentConfig() {
        XCTAssert(FileManager.default.changeCurrentDirectoryPath(Mock.Dir.remoteConfigParent))

        assertEqualExceptForFileGraph(
            Configuration(
                configurationFiles: ["main.yml"],
                mockedNetworkResults: [
                    "https://www.mock.com":
                    """
                    included:
                      - Test/Test1
                      - Test/Test2

                    excluded:
                      - Test/Test1/Test
                      - Test/Test2/Test

                    line_length: 80
                    """,
                ]
            ),
            Configuration(configurationFiles: ["expected.yml"])
        )
    }

    func testsRemoteConfigNotAllowedToReferenceLocalConfig() {
        XCTAssert(FileManager.default.changeCurrentDirectoryPath(Mock.Dir.remoteConfigLocalRef))

        // If the remote file is not allowed to reference a local file, the config should equal the default config.
        XCTAssertEqual(
            Configuration(
                configurationFiles: [], // not specifying a file means the .swiftlint.yml will be used
                mockedNetworkResults: [
                    "https://www.mock.com":
                    """
                    line_length: 60

                    child_config: child2.yml
                    """,
                ]
            ),
            Configuration()
        )
    }

    func testRemoteConfigCycleDetection() {
        XCTAssert(FileManager.default.changeCurrentDirectoryPath(Mock.Dir.remoteConfigCycle))

        // If the cycle is properly detected, the config should equal the default config.
        XCTAssertEqual(
            Configuration(
                configurationFiles: [], // not specifying a file means the .swiftlint.yml will be used
                mockedNetworkResults: [
                    "https://www.mock.com":
                    """
                    child_config: https://www.mock.com
                    """,
                ]
            ),
            Configuration()
        )
    }

    // MARK: - Helpers
    /// This helper function checks whether two configurations are equal except for their file graph.
    /// This is needed to test a child/parent merged config against an expected config.
    func assertEqualExceptForFileGraph(_ configuration1: Configuration, _ configuration2: Configuration) {
        XCTAssertEqual(
            configuration1.rulesWrapper.disabledRuleIdentifiers,
            configuration2.rulesWrapper.disabledRuleIdentifiers
        )

        XCTAssertEqual(
            configuration1.rules.map { type(of: $0).identifier },
            configuration2.rules.map { type(of: $0).identifier }
        )

        XCTAssertEqual(
            Set(configuration1.rulesWrapper.allRulesWrapped.map {
                $0.rule.createConfigurationDescription().oneLiner()
            }),
            Set(configuration2.rulesWrapper.allRulesWrapped.map {
                $0.rule.createConfigurationDescription().oneLiner()
            })
        )

        XCTAssertEqual(Set(configuration1.includedPaths), Set(configuration2.includedPaths))

        XCTAssertEqual(Set(configuration1.excludedPaths), Set(configuration2.excludedPaths))
    }
}

private extension Configuration {
    static func emptyDefaultConfiguration() -> Self {
        Configuration(rulesMode: .defaultConfiguration(disabled: [], optIn: []))
    }
    static func optInDefaultConfiguration(_ ruleIdentifier: String) -> Self {
        Configuration(rulesMode: .defaultConfiguration(disabled: [], optIn: [ruleIdentifier]))
    }
    static func optInDisabledDefaultConfiguration(_ ruleIdentifier: String) -> Self {
        Configuration(rulesMode: .defaultConfiguration(disabled: [ruleIdentifier], optIn: [ruleIdentifier]))
    }
    static func disabledDefaultConfiguration(_ ruleIdentifier: String) -> Self {
        Configuration(rulesMode: .defaultConfiguration(disabled: [ruleIdentifier], optIn: []))
    }
    static func emptyOnlyConfiguration() -> Self { Configuration(rulesMode: .onlyConfiguration([])) }
    static func enabledOnlyConfiguration(_ ruleIdentifier: String) -> Self {
        Configuration(rulesMode: .onlyConfiguration([ruleIdentifier]))
    }
    static func allEnabledConfiguration() -> Self { Configuration(rulesMode: .allCommandLine)}
    static func onlyRuleConfiguration(_ ruleIdentifier: String) -> Self {
        Configuration(rulesMode: .onlyCommandLine([ruleIdentifier]))
    }
}
