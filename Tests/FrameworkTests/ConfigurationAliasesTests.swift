import SwiftLintFramework
import TestHelpers
import Testing

@Suite
struct ConfigurationAliasesTests {
    private let testRuleList = RuleList(rules: RuleWithLevelsMock.self)

    @Test
    func configuresCorrectlyFromDeprecatedAlias() throws {
        let ruleConfiguration = [1, 2]
        let config = ["mock": ruleConfiguration]
        let rules = try testRuleList.allRulesWrapped(configurationDict: config).map(\.rule)
        #expect(rules == [try RuleWithLevelsMock(configuration: ruleConfiguration)])
    }

    @Test
    func returnsNilWithDuplicatedConfiguration() {
        let dict = ["mock": [1, 2], "severity_level_mock": [1, 3]]
        let configuration = try? Configuration(dict: dict, ruleList: testRuleList)
        #expect(configuration == nil)
    }

    @Test
    func initsFromDeprecatedAlias() {
        let ruleConfiguration = [1, 2]
        let configuration = try? Configuration(dict: ["mock": ruleConfiguration], ruleList: testRuleList)
        #expect(configuration != nil)
    }

    @Test
    func onlyRulesFromDeprecatedAlias() {
        // swiftlint:disable:next force_try
        let configuration = try! Configuration(dict: ["only_rules": ["mock"]], ruleList: testRuleList)
        let configuredIdentifiers = configuration.rules.map {
            type(of: $0).identifier
        }
        #expect(configuredIdentifiers == ["severity_level_mock"])
    }

    @Test
    func disabledRulesFromDeprecatedAlias() {
        // swiftlint:disable:next force_try
        let configuration = try! Configuration(dict: ["disabled_rules": ["mock"]], ruleList: testRuleList)
        #expect(configuration.rules.isEmpty)
    }
}
