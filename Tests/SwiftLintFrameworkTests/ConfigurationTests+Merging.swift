@testable import SwiftLintFramework
import XCTest

private extension Configuration {
    func contains<T: Rule>(rule: T.Type) -> Bool {
        return rules.contains { $0 is T }
    }
}

extension ConfigurationTests {
    // MARK: Rules Merging
    func testMerge() {
        XCTAssertFalse(projectMockConfig0.contains(rule: ForceCastRule.self))
        XCTAssertTrue(projectMockConfig2.contains(rule: ForceCastRule.self))
        let config0Merge2 = projectMockConfig0.merged(withChild: projectMockConfig2)
        XCTAssertFalse(config0Merge2.contains(rule: ForceCastRule.self))
        XCTAssertTrue(projectMockConfig0.contains(rule: TodoRule.self))
        XCTAssertTrue(projectMockConfig2.contains(rule: TodoRule.self))
        XCTAssertTrue(config0Merge2.contains(rule: TodoRule.self))
        XCTAssertFalse(projectMockConfig3.contains(rule: TodoRule.self))
        XCTAssertFalse(config0Merge2.merged(withChild: projectMockConfig3).contains(rule: TodoRule.self))
    }

    // MARK: Merging Aspects
    func testWarningThresholdMerging() {
        func configuration(forWarningThreshold warningThreshold: Int?) -> Configuration {
            return Configuration(
                ruleList: masterRuleList,
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

    func testWhitelistedRulesMerging() {
        let baseConfiguration = Configuration(rulesMode: .default(disabled: [],
                                                                  optIn: [ForceTryRule.description.identifier,
                                                                          ForceCastRule.description.identifier]))
        let whitelistedConfiguration = Configuration(rulesMode: .whitelisted([TodoRule.description.identifier]))
        XCTAssertTrue(baseConfiguration.contains(rule: TodoRule.self))
        XCTAssertEqual(whitelistedConfiguration.rules.count, 1)
        XCTAssertTrue(whitelistedConfiguration.rules[0] is TodoRule)
        let mergedConfiguration1 = baseConfiguration.merged(withChild: whitelistedConfiguration)
        XCTAssertEqual(mergedConfiguration1.rules.count, 1)
        XCTAssertTrue(mergedConfiguration1.rules[0] is TodoRule)

        // Also test the other way around
        let mergedConfiguration2 = whitelistedConfiguration.merged(withChild: baseConfiguration)
        XCTAssertEqual(mergedConfiguration2.rules.count, 3) // 2 opt-ins + 1 from the whitelisted rules
        XCTAssertTrue(mergedConfiguration2.contains(rule: TodoRule.self))
        XCTAssertTrue(mergedConfiguration2.contains(rule: ForceCastRule.self))
        XCTAssertTrue(mergedConfiguration2.contains(rule: ForceTryRule.self))
    }

    func testCustomRulesMerging() {
        let mergedConfiguration = projectMockConfig0CustomRules.merged(withChild: projectMockConfig2CustomRules)
        guard let mergedCustomRules = mergedConfiguration.rules.first(where: { $0 is CustomRules }) as? CustomRules
            else {
            return XCTFail("Custom rule are expected to be present")
        }
        XCTAssertTrue(
            mergedCustomRules.configuration.customRuleConfigurations.contains(where: { $0.identifier == "no_abc" })
        )
        XCTAssertTrue(
            mergedCustomRules.configuration.customRuleConfigurations.contains(where: { $0.identifier == "no_abcd" })
        )
    }

    func testMergingAllowsDisablingParentsCustomRules() {
        let mergedConfiguration = projectMockConfig0CustomRules.merged(withChild: projectMockConfig2CustomRulesDisabled)
        guard let mergedCustomRules = mergedConfiguration.rules.first(where: { $0 is CustomRules }) as? CustomRules
            else {
            return XCTFail("Custom rule are expected to be present")
        }
        XCTAssertFalse(
            mergedCustomRules.configuration.customRuleConfigurations.contains(where: { $0.identifier == "no_abc" })
        )
        XCTAssertTrue(
            mergedCustomRules.configuration.customRuleConfigurations.contains(where: { $0.identifier == "no_abcd" })
        )
    }

    // MARK: Nested Configurations
    func testNestedConfigurationLevel0() {
        XCTAssertEqual(projectMockConfig0.configuration(for: SwiftLintFile(path: projectMockSwift0)!),
                       projectMockConfig0)
    }

    func testNestedConfigurationLevel1() {
        XCTAssertEqual(projectMockConfig0.configuration(for: SwiftLintFile(path: projectMockSwift1)!),
                       projectMockConfig0)
    }

    func testNestedConfigurationLevel2() {
        XCTAssertEqual(projectMockConfig0.configuration(for: SwiftLintFile(path: projectMockSwift2)!),
                       projectMockConfig0.merged(withChild: projectMockConfig2))
    }

    func testNestedConfigurationLevel3() {
        XCTAssertEqual(projectMockConfig0.configuration(for: SwiftLintFile(path: projectMockSwift3)!),
                       projectMockConfig0.merged(withChild: projectMockConfig3))
    }

    func testParentConfigIsIgnoredAsNestedConfiguration() {
        // If a configuration has already been used to build the main config,
        // it should not again be regarded as a nested config
        XCTAssertEqual(
            projectMockNestedConfig.configuration(for: SwiftLintFile(path: projectMockNestedSubSwift)!),
            projectMockNestedConfig
        )
    }
}
