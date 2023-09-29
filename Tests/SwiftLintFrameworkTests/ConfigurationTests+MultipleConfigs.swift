@testable import SwiftLintBuiltInRules
@testable import SwiftLintCore
import XCTest

// swiftlint:disable file_length

private extension Configuration {
    func contains<T: Rule>(rule: T.Type) -> Bool {
        return rules.contains { $0 is T }
    }
}

extension ConfigurationTests {
    // MARK: - Rules Merging
    func testMerge() {
        let config0Merge2 = Mock.Config._0.merged(withChild: Mock.Config._2, rootDirectory: "")

        XCTAssertFalse(Mock.Config._0.contains(rule: ForceCastRule.self))
        XCTAssertTrue(Mock.Config._2.contains(rule: ForceCastRule.self))
        XCTAssertFalse(config0Merge2.contains(rule: ForceCastRule.self))

        XCTAssertTrue(Mock.Config._0.contains(rule: TodoRule.self))
        XCTAssertTrue(Mock.Config._2.contains(rule: TodoRule.self))
        XCTAssertTrue(config0Merge2.contains(rule: TodoRule.self))

        XCTAssertFalse(Mock.Config._3.contains(rule: TodoRule.self))
        XCTAssertFalse(
            config0Merge2.merged(withChild: Mock.Config._3, rootDirectory: "").contains(rule: TodoRule.self)
        )
    }

    // MARK: - Merging Aspects
    func testWarningThresholdMerging() {
        func configuration(forWarningThreshold warningThreshold: Int?) -> Configuration {
            return Configuration(
                warningThreshold: warningThreshold,
                reporter: XcodeReporter.identifier
            )
        }
        XCTAssertEqual(configuration(forWarningThreshold: 3)
            .merged(withChild: configuration(forWarningThreshold: 2), rootDirectory: "").warningThreshold,
                       2)
        XCTAssertEqual(configuration(forWarningThreshold: nil)
            .merged(withChild: configuration(forWarningThreshold: 2), rootDirectory: "").warningThreshold,
                       2)
        XCTAssertEqual(configuration(forWarningThreshold: 3)
            .merged(withChild: configuration(forWarningThreshold: nil), rootDirectory: "").warningThreshold,
                       3)
        XCTAssertNil(configuration(forWarningThreshold: nil)
            .merged(withChild: configuration(forWarningThreshold: nil), rootDirectory: "").warningThreshold)
    }

    func testOnlyRulesMerging() {
        let baseConfiguration = Configuration(rulesMode: .default(disabled: [],
                                                                  optIn: [ForceTryRule.description.identifier,
                                                                          ForceCastRule.description.identifier]))
        let onlyConfiguration = Configuration(rulesMode: .only([TodoRule.description.identifier]))
        XCTAssertTrue(baseConfiguration.contains(rule: TodoRule.self))
        XCTAssertEqual(onlyConfiguration.rules.count, 1)
        XCTAssertTrue(onlyConfiguration.rules[0] is TodoRule)

        let mergedConfiguration1 = baseConfiguration.merged(withChild: onlyConfiguration, rootDirectory: "")
        XCTAssertEqual(mergedConfiguration1.rules.count, 1)
        XCTAssertTrue(mergedConfiguration1.rules[0] is TodoRule)

        // Also test the other way around
        let mergedConfiguration2 = onlyConfiguration.merged(withChild: baseConfiguration, rootDirectory: "")
        XCTAssertEqual(mergedConfiguration2.rules.count, 3) // 2 opt-ins + 1 from the only rules
        XCTAssertTrue(mergedConfiguration2.contains(rule: TodoRule.self))
        XCTAssertTrue(mergedConfiguration2.contains(rule: ForceCastRule.self))
        XCTAssertTrue(mergedConfiguration2.contains(rule: ForceTryRule.self))
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
            FileManager.default.changeCurrentDirectoryPath(path)

            assertEqualExceptForFileGraph(
                Configuration(configurationFiles: ["main.yml"]),
                Configuration(configurationFiles: ["expected.yml"])
            )
        }
    }

    func testValidParentConfig() {
        for path in [Mock.Dir.parentConfigTest1, Mock.Dir.parentConfigTest2] {
            FileManager.default.changeCurrentDirectoryPath(path)

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
            FileManager.default.changeCurrentDirectoryPath(path)

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
            Mock.Dir.parentConfigCycle3
        ] {
            FileManager.default.changeCurrentDirectoryPath(path)

            // If the cycle is properly detected, the config should equal the default config.
            XCTAssertEqual(
                Configuration(configurationFiles: []), // not specifying a file means the .swiftlint.yml will be used
                Configuration()
            )
        }
    }

    func testCommandLineConfigsCycleDetection() {
        FileManager.default.changeCurrentDirectoryPath(Mock.Dir.childConfigCycle4)

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
            TestCase(optedInInParent: true, disabledInParent: true, optedInInChild: true, disabledInChild: true, isEnabled: false)
            // swiftlint:enable line_length
        ]
        XCTAssertEqual(testCases.unique.count, 4 * 4)
        let ruleType = ImplicitReturnRule.self
        XCTAssertTrue((ruleType as Any) is any OptInRule.Type)
        let ruleIdentifier = ruleType.description.identifier
        for testCase in testCases {
            let parentConfiguration = Configuration(rulesMode: .default(
                disabled: testCase.disabledInParent ? [ruleIdentifier] : [],
                optIn: testCase.optedInInParent ? [ruleIdentifier] : []
            ))
            let childConfiguration = Configuration(rulesMode: .default(
                disabled: testCase.disabledInChild ? [ruleIdentifier] : [],
                optIn: testCase.optedInInChild ? [ruleIdentifier] : []
            ))
            let mergedConfiguration = parentConfiguration.merged(withChild: childConfiguration, rootDirectory: "")
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
            TestCase(disabledInParent: true, disabledInChild: true, isEnabled: false)
        ]
        XCTAssertEqual(testCases.unique.count, 2 * 2)
        let ruleType = BlanketDisableCommandRule.self
        XCTAssertFalse(ruleType is any OptInRule.Type)
        let ruleIdentifier = ruleType.description.identifier
        for testCase in testCases {
            let parentConfiguration = Configuration(
                rulesMode: .default(disabled: testCase.disabledInParent ? [ruleIdentifier] : [], optIn: [])
            )
            let childConfiguration = Configuration(
                rulesMode: .default(disabled: testCase.disabledInChild ? [ruleIdentifier] : [], optIn: [])
            )
            let mergedConfiguration = parentConfiguration.merged(withChild: childConfiguration, rootDirectory: "")
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
            TestCase(optedInInChild: true, disabledInChild: true, isEnabled: false)
        ]
        XCTAssertEqual(testCases.unique.count, 2 * 2)
        let ruleType = ImplicitReturnRule.self
        XCTAssertTrue((ruleType as Any) is any OptInRule.Type)
        let ruleIdentifier = ruleType.description.identifier
        let parentConfiguration = Configuration(rulesMode: .only([ruleIdentifier]))
        for testCase in testCases {
            let childConfiguration = Configuration(rulesMode: .default(
                disabled: testCase.disabledInChild ? [ruleIdentifier] : [],
                optIn: testCase.optedInInChild ? [ruleIdentifier] : []
            ))
            let mergedConfiguration = parentConfiguration.merged(withChild: childConfiguration, rootDirectory: "")
            let isEnabled = mergedConfiguration.contains(rule: ruleType)
            XCTAssertEqual(isEnabled, testCase.isEnabled, testCase.message)
        }
    }

    // MARK: Warnings about configurations for disabled rules
    func testOptInRulesWithDefaultConfigurationWarnings() {
        struct TestCase: Equatable {
            let parentConfiguration: Configuration?
            let disabledRules: Set<String>
            let optInRules: Set<String>
            let expectedMessage: String?
        }
        let ruleType = ImplicitReturnRule.self
        let ruleIdentifier = ruleType.description.identifier

        let emptyConfiguration = Configuration(rulesMode: .default(disabled: [], optIn: []))
        let optInConfiguration = Configuration(rulesMode: .default(disabled: [], optIn: [ruleIdentifier]))
        let optInDisabledConfiguration = Configuration(rulesMode: .default(disabled: [ruleIdentifier], optIn: [ruleIdentifier]))
        let disabledConfiguration = Configuration(rulesMode: .default(disabled: [ruleIdentifier], optIn: []))
        
        let notEnabledMessage = "Found a configuration for '\(ruleIdentifier)' rule, but it is not enabled on 'opt_in_rules'."
        let disabledInParentMessage = "Found a configuration for '\(ruleIdentifier)' rule, but it is disabled in a parent configuration."
        let disabledMessage = "Found a configuration for '\(ruleIdentifier)' rule, but it is disabled on 'disabled_rules'."
        
        let testCases: [TestCase] = [
            TestCase(parentConfiguration: nil, disabledRules: [], optInRules: [], expectedMessage: notEnabledMessage),
            TestCase(parentConfiguration: emptyConfiguration, disabledRules: [], optInRules: [], expectedMessage: notEnabledMessage),
            TestCase(parentConfiguration: optInConfiguration, disabledRules: [], optInRules: [], expectedMessage: nil),
            TestCase(parentConfiguration: optInDisabledConfiguration, disabledRules: [], optInRules: [], expectedMessage: disabledInParentMessage),
            TestCase(parentConfiguration: disabledConfiguration, disabledRules: [], optInRules: [], expectedMessage: disabledInParentMessage),

            TestCase(parentConfiguration: nil, disabledRules: [], optInRules: [ruleIdentifier], expectedMessage: nil),
            TestCase(parentConfiguration: emptyConfiguration, disabledRules: [], optInRules: [ruleIdentifier], expectedMessage: nil),
            TestCase(parentConfiguration: optInConfiguration, disabledRules: [], optInRules: [ruleIdentifier], expectedMessage: nil),
            TestCase(parentConfiguration: optInDisabledConfiguration, disabledRules: [], optInRules: [ruleIdentifier], expectedMessage: nil),
            TestCase(parentConfiguration: disabledConfiguration, disabledRules: [], optInRules: [ruleIdentifier], expectedMessage: nil),

            TestCase(parentConfiguration: nil, disabledRules: [ruleIdentifier], optInRules: [ruleIdentifier], expectedMessage: disabledMessage),
            TestCase(parentConfiguration: emptyConfiguration, disabledRules: [ruleIdentifier], optInRules: [ruleIdentifier], expectedMessage: disabledMessage),
            TestCase(parentConfiguration: optInConfiguration, disabledRules: [ruleIdentifier], optInRules: [ruleIdentifier], expectedMessage: disabledMessage),
            TestCase(parentConfiguration: optInDisabledConfiguration, disabledRules: [ruleIdentifier], optInRules: [ruleIdentifier], expectedMessage: disabledMessage),
            TestCase(parentConfiguration: disabledConfiguration, disabledRules: [ruleIdentifier], optInRules: [ruleIdentifier], expectedMessage: disabledMessage),

            TestCase(parentConfiguration: nil, disabledRules: [ruleIdentifier], optInRules: [], expectedMessage: disabledMessage),
            TestCase(parentConfiguration: emptyConfiguration, disabledRules: [ruleIdentifier], optInRules: [], expectedMessage: disabledMessage),
            TestCase(parentConfiguration: optInConfiguration, disabledRules: [ruleIdentifier], optInRules: [], expectedMessage: disabledMessage),
            TestCase(parentConfiguration: optInDisabledConfiguration, disabledRules: [ruleIdentifier], optInRules: [], expectedMessage: disabledMessage),
            TestCase(parentConfiguration: disabledConfiguration, disabledRules: [ruleIdentifier], optInRules: [], expectedMessage: disabledMessage),
        ]

        for testCase in testCases {
            testConfiguredRuleValidation(
                ruleType: ruleType,
                parentConfiguration: testCase.parentConfiguration,
                disabledRules: testCase.disabledRules,
                optInRules: testCase.optInRules,
                expectedMessage: testCase.expectedMessage
            )
        }
    }
    
    func testOptInRulesWithOnlyConfigurationWarnings() {
        struct TestCase: Equatable {
            let parentConfiguration: Configuration?
            let disabledRules: Set<String>
            let optInRules: Set<String>
            let expectedMessage: String?
        }

        let ruleType = ImplicitReturnRule.self
        let ruleIdentifier = ruleType.description.identifier

        let emptyConfiguration = Configuration(rulesMode: .only([]))
        let enabledConfiguration = Configuration(rulesMode: .only([ruleIdentifier]))
        
        let notEnabledMessage = "Found a configuration for '\(ruleIdentifier)' rule, but it is not enabled on 'opt_in_rules'."
        let disabledMessage = "Found a configuration for '\(ruleIdentifier)' rule, but it is disabled on 'disabled_rules'."

        let testCases: [TestCase] = [
            TestCase(parentConfiguration: nil, disabledRules: [], optInRules: [], expectedMessage: notEnabledMessage),
            TestCase(parentConfiguration: emptyConfiguration, disabledRules: [], optInRules: [], expectedMessage: notEnabledMessage),
            TestCase(parentConfiguration: enabledConfiguration, disabledRules: [], optInRules: [], expectedMessage: nil),
            
            TestCase(parentConfiguration: nil, disabledRules: [], optInRules: [ruleIdentifier], expectedMessage: nil),
            TestCase(parentConfiguration: emptyConfiguration, disabledRules: [], optInRules: [ruleIdentifier], expectedMessage: nil),
            TestCase(parentConfiguration: enabledConfiguration, disabledRules: [], optInRules: [ruleIdentifier], expectedMessage: nil),

            TestCase(parentConfiguration: nil, disabledRules: [ruleIdentifier], optInRules: [ruleIdentifier], expectedMessage: disabledMessage),
            TestCase(parentConfiguration: emptyConfiguration, disabledRules: [ruleIdentifier], optInRules: [ruleIdentifier], expectedMessage: disabledMessage),
            TestCase(parentConfiguration: enabledConfiguration, disabledRules: [ruleIdentifier], optInRules: [ruleIdentifier], expectedMessage: disabledMessage),

            TestCase(parentConfiguration: nil, disabledRules: [ruleIdentifier], optInRules: [], expectedMessage: disabledMessage),
            TestCase(parentConfiguration: emptyConfiguration, disabledRules: [ruleIdentifier], optInRules: [], expectedMessage: disabledMessage),
            TestCase(parentConfiguration: enabledConfiguration, disabledRules: [ruleIdentifier], optInRules: [], expectedMessage: disabledMessage),
        ]
        
        for testCase in testCases {
            testConfiguredRuleValidation(
                ruleType: ruleType,
                parentConfiguration: testCase.parentConfiguration,
                disabledRules: testCase.disabledRules,
                optInRules: testCase.optInRules,
                expectedMessage: testCase.expectedMessage
            )
        }
    }
    
    private func testConfiguredRuleValidation(
        ruleType: Rule.Type,
        parentConfiguration: Configuration?,
        disabledRules: Set<String>,
        optInRules: Set<String>,
        expectedMessage: String? = nil
    ) {
        let ruleIdentifier = ruleType.description.identifier
        let message = "Found a configuration for '\(ruleIdentifier)' rule"
        let issue = Configuration.validateConfiguredRuleIsEnabled(
            message: message,
            parentConfiguration: parentConfiguration,
            disabledRules: disabledRules,
            optInRules: optInRules,
            ruleType: ruleType
        )
        if let expectedMessage {
            if let issue {
                XCTAssertEqual(issue.message, expectedMessage)
            } else {
                XCTFail("issue was nil")
            }
        } else {
            XCTAssertNil(issue)
        }
    }

    // MARK: - Remote Configs
    func testValidRemoteChildConfig() {
        FileManager.default.changeCurrentDirectoryPath(Mock.Dir.remoteConfigChild)

        assertEqualExceptForFileGraph(
            Configuration(
                configurationFiles: ["main.yml"],
                mockedNetworkResults: [
                    "https://www.mock.com":
                    """
                    included:
                      - Test/Test1/Test/Test
                      - Test/Test2/Test/Test
                    """
                ]
            ),
            Configuration(configurationFiles: ["expected.yml"])
        )
    }

    func testValidRemoteParentConfig() {
        FileManager.default.changeCurrentDirectoryPath(Mock.Dir.remoteConfigParent)

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
                    """
                ]
            ),
            Configuration(configurationFiles: ["expected.yml"])
        )
    }

    func testsRemoteConfigNotAllowedToReferenceLocalConfig() {
        FileManager.default.changeCurrentDirectoryPath(Mock.Dir.remoteConfigLocalRef)

        // If the remote file is not allowed to reference a local file, the config should equal the default config.
        XCTAssertEqual(
            Configuration(
                configurationFiles: [], // not specifying a file means the .swiftlint.yml will be used
                mockedNetworkResults: [
                    "https://www.mock.com":
                    """
                    line_length: 60

                    child_config: child2.yml
                    """
                ]
            ),
            Configuration()
        )
    }

    func testRemoteConfigCycleDetection() {
        FileManager.default.changeCurrentDirectoryPath(Mock.Dir.remoteConfigCycle)

        // If the cycle is properly detected, the config should equal the default config.
        XCTAssertEqual(
            Configuration(
                configurationFiles: [], // not specifying a file means the .swiftlint.yml will be used
                mockedNetworkResults: [
                    "https://www.mock.com":
                    """
                    child_config: https://www.mock.com
                    """
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
            configuration1.rules.map { type(of: $0).description.identifier },
            configuration2.rules.map { type(of: $0).description.identifier }
        )

        XCTAssertEqual(
            Set(configuration1.rulesWrapper.allRulesWrapped.map { $0.rule.configurationDescription.oneLiner() }),
            Set(configuration2.rulesWrapper.allRulesWrapped.map { $0.rule.configurationDescription.oneLiner() })
        )

        XCTAssertEqual(Set(configuration1.includedPaths), Set(configuration2.includedPaths))

        XCTAssertEqual(Set(configuration1.excludedPaths), Set(configuration2.excludedPaths))
    }
}
