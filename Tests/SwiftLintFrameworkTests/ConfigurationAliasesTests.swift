@testable import SwiftLintFramework
import XCTest

final class ConfigurationAliasesTests: XCTestCase {
    let testRuleList = RuleList(rules: RuleWithLevelsMock.self)

    func testConfiguresCorrectlyFromDeprecatedAlias() throws {
        let ruleConfiguration = [1, 2]
        let config = ["mock": ruleConfiguration]
        let rules = try testRuleList.allRules(configurationDict: config)
        XCTAssertTrue(rules == [try RuleWithLevelsMock(configuration: ruleConfiguration)])
    }

    func testReturnsNilWithDuplicatedConfiguration() {
        let dict = ["mock": [1, 2], "severity_level_mock": [1, 3]]
        let configuration = Configuration(dict: dict, ruleList: testRuleList)
        XCTAssertNil(configuration)
    }

    func testInitsFromDeprecatedAlias() {
        let ruleConfiguration = [1, 2]
        let configuration = Configuration(dict: ["mock": ruleConfiguration], ruleList: testRuleList)
        XCTAssertNotNil(configuration)
    }

    func testWhitelistRulesFromDeprecatedAlias() {
        let configuration = Configuration(dict: ["whitelist_rules": ["mock"]], ruleList: testRuleList)!
        let configuredIdentifiers = configuration.rules.map {
            type(of: $0).description.identifier
        }
        XCTAssertEqual(configuredIdentifiers, ["severity_level_mock"])
    }

    func testDisabledRulesFromDeprecatedAlias() {
        let configuration = Configuration(dict: ["disabled_rules": ["mock"]], ruleList: testRuleList)!
        XCTAssert(configuration.rules.isEmpty)
    }
}
