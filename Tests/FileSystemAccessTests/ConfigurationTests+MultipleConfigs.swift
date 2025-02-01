import Foundation
import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules
@testable import SwiftLintFramework

// swiftlint:disable file_length

private extension Configuration {
    func contains<T: Rule>(rule _: T.Type) -> Bool {
        rules.contains { $0 is T }
    }
}

// swiftlint:disable:next type_body_length
extension FileSystemAccessTestSuite.ConfigurationTests {
    // MARK: - Rules Merging
    @Test
    @WorkingDirectory(path: Constants.Dir.level0)
    func merge() {
        let config0Merge2 = Constants.Config._0.merged(withChild: Constants.Config._2)

        #expect(!Constants.Config._0.contains(rule: ForceCastRule.self))
        #expect(Constants.Config._2.contains(rule: ForceCastRule.self))
        #expect(!config0Merge2.contains(rule: ForceCastRule.self))

        #expect(Constants.Config._0.contains(rule: TodoRule.self))
        #expect(Constants.Config._2.contains(rule: TodoRule.self))
        #expect(config0Merge2.contains(rule: TodoRule.self))

        #expect(!Constants.Config._3.contains(rule: TodoRule.self))
        #expect(!config0Merge2.merged(withChild: Constants.Config._3).contains(rule: TodoRule.self))
    }

    // MARK: - Merging Aspects
    @Test
    func warningThresholdMerging() {
        func configuration(forWarningThreshold warningThreshold: Int?) -> Configuration {
            Configuration(
                warningThreshold: warningThreshold,
                reporter: XcodeReporter.identifier
            )
        }
        #expect(configuration(forWarningThreshold: 3)
            .merged(withChild: configuration(forWarningThreshold: 2)).warningThreshold == 2)
        #expect(configuration(forWarningThreshold: nil)
            .merged(withChild: configuration(forWarningThreshold: 2)).warningThreshold == 2)
        #expect(configuration(forWarningThreshold: 3)
            .merged(withChild: configuration(forWarningThreshold: nil)).warningThreshold == 3)
        #expect(configuration(forWarningThreshold: nil)
            .merged(withChild: configuration(forWarningThreshold: nil)).warningThreshold == nil)
    }

    @Test
    func onlyRulesMerging() {
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
        #expect(baseConfiguration.contains(rule: TodoRule.self))
        #expect(onlyConfiguration.rules.count == 1)
        #expect(onlyConfiguration.rules.first is TodoRule)

        let mergedConfiguration1 = baseConfiguration.merged(withChild: onlyConfiguration)
        #expect(mergedConfiguration1.rules.count == 1)
        #expect(mergedConfiguration1.rules.first is TodoRule)

        // Also test the other way around
        let mergedConfiguration2 = onlyConfiguration.merged(withChild: baseConfiguration)
        #expect(mergedConfiguration2.rules.count == 3) // 2 opt-ins + 1 from the only rules
        #expect(mergedConfiguration2.contains(rule: TodoRule.self))
        #expect(mergedConfiguration2.contains(rule: ForceCastRule.self))
        #expect(mergedConfiguration2.contains(rule: ForceTryRule.self))
    }

    @Test
    func onlyRuleMerging() {
        let ruleIdentifier = TodoRule.identifier
        let onlyRuleConfiguration = Configuration.onlyRuleConfiguration(ruleIdentifier)

        let emptyDefaultConfiguration = Configuration.emptyDefaultConfiguration()
        let mergedConfiguration1 = onlyRuleConfiguration.merged(withChild: emptyDefaultConfiguration)
        #expect(mergedConfiguration1.rules.count == 1)
        #expect(mergedConfiguration1.rules.first is TodoRule)

        let disabledDefaultConfiguration = Configuration.disabledDefaultConfiguration(ruleIdentifier)
        let mergedConfiguration2 = onlyRuleConfiguration.merged(withChild: disabledDefaultConfiguration)
        #expect(mergedConfiguration2.rules.isEmpty)

        let enabledOnlyConfiguration = Configuration.enabledOnlyConfiguration(ForceTryRule.identifier)
        let mergedConfiguration3 = onlyRuleConfiguration.merged(withChild: enabledOnlyConfiguration)
        #expect(mergedConfiguration3.rules.count == 1)
        #expect(mergedConfiguration3.rules.first is TodoRule)
    }

    @Test
    func customRulesMerging() {
        let mergedConfiguration = Constants.Config._0CustomRules.merged(
            withChild: Constants.Config._2CustomRules,
            rootDirectory: ""
        )
        guard let mergedCustomRules = mergedConfiguration.rules.customRules
            else {
            Issue.record("Custom rules are expected to be present")
            return
        }
        #expect(
            mergedCustomRules.configuration.customRuleConfigurations.contains { $0.identifier == "no_abc" }
        )
        #expect(
            mergedCustomRules.configuration.customRuleConfigurations.contains { $0.identifier == "no_abcd" }
        )
    }

    @Test
    func mergingAllowsDisablingParentsCustomRules() {
        let mergedConfiguration = Constants.Config._0CustomRules.merged(
            withChild: Constants.Config._2CustomRulesDisabled,
            rootDirectory: ""
        )
        guard let mergedCustomRules = mergedConfiguration.rules.customRules
            else {
            Issue.record("Custom rules are expected to be present")
            return
        }
        #expect(!mergedCustomRules.configuration.customRuleConfigurations.contains { $0.identifier == "no_abc" })
        #expect(mergedCustomRules.configuration.customRuleConfigurations.contains { $0.identifier == "no_abcd" })
    }

    @Test
    func customRulesMergingWithOnlyRulesCase1() {
        // The base configuration is in only rules mode
        // The child configuration is in the default rules mode
        // => all custom rules should be considered
        let mergedConfiguration = Constants.Config._0CustomRulesOnly.merged(
            withChild: Constants.Config._2CustomRules,
            rootDirectory: ""
        )
        guard let mergedCustomRules = mergedConfiguration.rules.customRules
            else {
            Issue.record("Custom rules are expected to be present")
            return
        }
        #expect(
            mergedCustomRules.configuration.customRuleConfigurations.contains { $0.identifier == "no_abc" }
        )
        #expect(
            mergedCustomRules.configuration.customRuleConfigurations.contains { $0.identifier == "no_abcd" }
        )
    }

    @Test
    func customRulesMergingWithOnlyRulesCase2() {
        // The base configuration is in only rules mode
        // The child configuration is in the only rules mode
        // => only the custom rules from the child configuration should be considered
        // (because custom rules from base configuration would require explicit mention as one of the `only_rules`)
        let mergedConfiguration = Constants.Config._0CustomRulesOnly.merged(
            withChild: Constants.Config._2CustomRulesOnly,
            rootDirectory: ""
        )
        guard let mergedCustomRules = mergedConfiguration.rules.customRules
            else {
            Issue.record("Custom rules are expected to be present")
            return
        }
        #expect(!mergedCustomRules.configuration.customRuleConfigurations.contains { $0.identifier == "no_abc" })
        #expect(mergedCustomRules.configuration.customRuleConfigurations.contains { $0.identifier == "no_abcd" })
    }

    @Test
    func customRulesReconfiguration() {
        // Custom Rule severity gets reconfigured to "error"
        let mergedConfiguration = Constants.Config._0CustomRulesOnly.merged(
            withChild: Constants.Config._2CustomRulesReconfig,
            rootDirectory: ""
        )
        guard let mergedCustomRules = mergedConfiguration.rules.customRules
            else {
            Issue.record("Custom rules are expected to be present")
            return
        }
        #expect(
            mergedCustomRules.configuration.customRuleConfigurations.filter { $0.identifier == "no_abc" }.count == 1
        )
        guard let customRule = (mergedCustomRules.configuration.customRuleConfigurations.first {
            $0.identifier == "no_abc"
        }) else {
            Issue.record("Custom rule is expected to be present")
            return
        }
        #expect(customRule.severityConfiguration.severity == .error)
    }

    // MARK: - Nested Configurations
    @Test
    @WorkingDirectory(path: Constants.Dir.level0)
    func level0() {
        #expect(Constants.Config._0.configuration(for: SwiftLintFile(path: Constants.Swift._0)!) == Constants.Config._0)
    }

    @Test
    @WorkingDirectory(path: Constants.Dir.level0)
    func level1() {
        #expect(Constants.Config._0.configuration(for: SwiftLintFile(path: Constants.Swift._1)!) == Constants.Config._0)
    }

    @Test
    func level2() {
        let config = Constants.Config._0.configuration(for: SwiftLintFile(path: Constants.Swift._2)!)
        var config2 = Constants.Config._2
        config2.fileGraph = Configuration.FileGraph(rootDirectory: Constants.Dir.level2)

        #expect(config == Constants.Config._0.merged(withChild: config2, rootDirectory: config.rootDirectory))
    }

    @Test
    func level3() {
        let config = Constants.Config._0.configuration(for: SwiftLintFile(path: Constants.Swift._3)!)
        var config3 = Constants.Config._3
        config3.fileGraph = Configuration.FileGraph(rootDirectory: Constants.Dir.level3)

        #expect(config == Constants.Config._0.merged(withChild: config3, rootDirectory: config.rootDirectory))
    }

    @Test
    func nestedConfigurationForOnePathPassedIn() {
        // If a path to one or more configuration files is specified, nested configurations should be ignored
        let config = Configuration(configurationFiles: [Constants.Yml._0])
        #expect(config.configuration(for: SwiftLintFile(path: Constants.Swift._3)!) == config)
    }

    @Test
    func parentConfigIsIgnoredAsNestedConfiguration() {
        // If a configuration has already been used to build the main config,
        // it should not again be regarded as a nested config
        #expect(
            Constants.Config.nested.configuration(for: SwiftLintFile(path: Constants.Swift.nestedSub)!)
                == Constants.Config.nested
        )
    }

    // MARK: - Child & Parent Configs
    @Test(
        .disabled(if: isRunningWithBazel),
        arguments: [Constants.Dir.childConfigTest1, Constants.Dir.childConfigTest2],
    )
    @WorkingDirectory(path: Constants.Dir.emptyFolder)
    func validChildConfig(_ path: String) {
        #expect(FileManager.default.changeCurrentDirectoryPath(path))

        assertEqualExceptForFileGraph(
            Configuration(configurationFiles: ["main.yml"]),
            Configuration(configurationFiles: ["expected.yml"])
        )
    }

    @Test(arguments: [Constants.Dir.parentConfigTest1, Constants.Dir.parentConfigTest2])
    @WorkingDirectory(path: Constants.Dir.emptyFolder)
    func validParentConfig(_ path: String) {
        #expect(FileManager.default.changeCurrentDirectoryPath(path))

        assertEqualExceptForFileGraph(
            Configuration(configurationFiles: ["main.yml"]),
            Configuration(configurationFiles: ["expected.yml"])
        )
    }

    @Test(
        .disabled(if: isRunningWithBazel),
        arguments: [Constants.Dir.childConfigTest1, Constants.Dir.childConfigTest2],
    )
    @WorkingDirectory(path: Constants.Dir.emptyFolder)
    func commandLineChildConfigs(_ path: String) {
        #expect(FileManager.default.changeCurrentDirectoryPath(path))

        assertEqualExceptForFileGraph(
            Configuration(configurationFiles: ["main.yml", "child1.yml", "child2.yml"]),
            Configuration(configurationFiles: ["expected.yml"])
        )
    }

    @Test(
        arguments: [
            Constants.Dir.childConfigCycle1,
            Constants.Dir.childConfigCycle2,
            Constants.Dir.childConfigCycle3,
            Constants.Dir.parentConfigCycle1,
            Constants.Dir.parentConfigCycle2,
            Constants.Dir.parentConfigCycle3,
        ],
    )
    @WorkingDirectory(path: Constants.Dir.emptyFolder)
    func configCycleDetection(_ path: String) {
        #expect(FileManager.default.changeCurrentDirectoryPath(path))

        // If the cycle is properly detected, the config should equal the default config.
        #expect(Configuration(configurationFiles: []) == Configuration())
    }

    @Test
    @WorkingDirectory(path: Constants.Dir.childConfigCycle4)
    func commandLineConfigsCycleDetection() {
        // If the cycle is properly detected, the config should equal the default config.
        assertEqualExceptForFileGraph(
            Configuration(
                configurationFiles: ["main.yml", "child.yml"],
                useDefaultConfigOnFailure: true
            ),
            Configuration()
        )
    }

    @Test
    func parentChildOptInAndDisable() {
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
        #expect(testCases.unique.count == 4 * 4)
        let ruleType = ImplicitReturnRule.self
        #expect((ruleType as Any) is any OptInRule.Type)
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
            #expect(isEnabled == testCase.isEnabled, Comment(rawValue: testCase.message))
        }
    }

    @Test
    func parentChildDisableForDefaultRule() {
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
        #expect(testCases.unique.count == 2 * 2)
        let ruleType = BlanketDisableCommandRule.self
        #expect(!(ruleType is any OptInRule.Type))
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
            #expect(isEnabled == testCase.isEnabled, Comment(rawValue: testCase.message))
        }
    }

    @Test
    func parentOnlyRulesAndChildOptInAndDisabled() {
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
        #expect(testCases.unique.count == 2 * 2)
        let ruleType = ImplicitReturnRule.self
        #expect((ruleType as Any) is any OptInRule.Type)
        let ruleIdentifier = ruleType.identifier
        let parentConfiguration = Configuration(rulesMode: .onlyConfiguration([ruleIdentifier]))
        for testCase in testCases {
            let childConfiguration = Configuration(rulesMode: .defaultConfiguration(
                disabled: testCase.disabledInChild ? [ruleIdentifier] : [],
                optIn: testCase.optedInInChild ? [ruleIdentifier] : []
            ))
            let mergedConfiguration = parentConfiguration.merged(withChild: childConfiguration)
            let isEnabled = mergedConfiguration.contains(rule: ruleType)
            #expect(isEnabled == testCase.isEnabled, Comment(rawValue: testCase.message))
        }
    }

    // MARK: Warnings about configurations for disabled rules
    @Test
    func defaultConfigurationDisabledRuleWarnings() {
        let optInRuleType = ImplicitReturnRule.self
        #expect((optInRuleType as Any) is any OptInRule.Type)
        testDefaultConfigurationDisabledRuleWarnings(for: optInRuleType)

        let defaultRuleType = BlockBasedKVORule.self
        #expect(!((defaultRuleType as Any) is any OptInRule.Type))
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
            Issue.record("Configuration rulesMode was not the default")
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
        #expect(isEnabled == (issue == nil))
        guard let issue else {
            return
        }
        let ruleIdentifier = ruleType.identifier

        guard disabledRules.isEmpty, optInRules.isEmpty else {
            #expect(issue == Issue.ruleDisabledInDisabledRules(ruleID: ruleIdentifier))
            return
        }

        if parentConfiguration == nil ||
            parentConfiguration == Configuration.emptyDefaultConfiguration() {
            #expect(issue == Issue.ruleNotEnabledInOptInRules(ruleID: ruleIdentifier))
        } else if parentConfiguration == Configuration.emptyOnlyConfiguration() {
            if ruleType is any OptInRule.Type {
                #expect(issue == Issue.ruleNotEnabledInOptInRules(ruleID: ruleIdentifier))
            } else {
                #expect(issue == Issue.ruleNotEnabledInParentOnlyRules(ruleID: ruleIdentifier))
            }
        } else if parentConfiguration == Configuration.optInDisabledDefaultConfiguration(ruleIdentifier) ||
            parentConfiguration == Configuration.disabledDefaultConfiguration(ruleIdentifier) {
            #expect(issue == Issue.ruleDisabledInParentConfiguration(ruleID: ruleIdentifier))
        }
    }

    @Test
    func onlyConfigurationDisabledRulesWarnings() {
        let optInRuleType = ImplicitReturnRule.self
        #expect((optInRuleType as Any) is any OptInRule.Type)
        testOnlyConfigurationDisabledRulesWarnings(ruleType: optInRuleType)

        let defaultRuleType = BlockBasedKVORule.self
        #expect(!((defaultRuleType as Any) is any OptInRule.Type))
        testOnlyConfigurationDisabledRulesWarnings(ruleType: defaultRuleType)
    }

    private func testOnlyConfigurationDisabledRulesWarnings(ruleType: any Rule.Type) {
        let issue = Configuration.validateConfiguredRuleIsEnabled(onlyRules: [], ruleType: ruleType)
        #expect(issue == Issue.ruleNotPresentInOnlyRules(ruleID: ruleType.identifier))
        #expect(
            Configuration.validateConfiguredRuleIsEnabled(onlyRules: [ruleType.identifier], ruleType: ruleType) == nil
        )
    }

    // MARK: - Remote Configs
    @Test
    @WorkingDirectory(path: Constants.Dir.remoteConfigChild)
    func validRemoteChildConfig() {
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

    @Test
    @WorkingDirectory(path: Constants.Dir.remoteConfigParent)
    func validRemoteParentConfig() {
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

    @Test
    @WorkingDirectory(path: Constants.Dir.remoteConfigLocalRef)
    func sRemoteConfigNotAllowedToReferenceLocalConfig() {
        // If the remote file is not allowed to reference a local file, the config should equal the default config.
        #expect(
            Configuration(
                configurationFiles: [], // not specifying a file means the .swiftlint.yml will be used
                mockedNetworkResults: [
                    "https://www.mock.com":
                    """
                    line_length: 60

                    child_config: child2.yml
                    """,
                ]
            ) == Configuration()
        )
    }

    @Test
    @WorkingDirectory(path: Constants.Dir.remoteConfigCycle)
    func remoteConfigCycleDetection() {
        // If the cycle is properly detected, the config should equal the default config.
        #expect(
            Configuration(
                configurationFiles: [], // not specifying a file means the .swiftlint.yml will be used
                mockedNetworkResults: [
                    "https://www.mock.com":
                    """
                    child_config: https://www.mock.com
                    """,
                ]
            ) == Configuration()
        )
    }

    // MARK: - Helpers
    /// This helper function checks whether two configurations are equal except for their file graph.
    /// This is needed to test a child/parent merged config against an expected config.
    func assertEqualExceptForFileGraph(_ configuration1: Configuration, _ configuration2: Configuration) {
        #expect(
            configuration1.rulesWrapper.disabledRuleIdentifiers == configuration2.rulesWrapper.disabledRuleIdentifiers
        )
        #expect(
            configuration1.rules.map { type(of: $0).identifier } == configuration2.rules.map { type(of: $0).identifier }
        )
        #expect(
            Set(configuration1.rulesWrapper.allRulesWrapped.map {
                $0.rule.createConfigurationDescription().oneLiner()
            }) == Set(configuration2.rulesWrapper.allRulesWrapped.map {
                $0.rule.createConfigurationDescription().oneLiner()
            })
        )
        #expect(Set(configuration1.includedPaths) == Set(configuration2.includedPaths))
        #expect(Set(configuration1.excludedPaths) == Set(configuration2.excludedPaths))
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
