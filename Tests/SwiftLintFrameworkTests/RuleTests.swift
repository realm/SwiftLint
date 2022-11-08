@testable import SwiftLintFramework
import XCTest

struct RuleWithLevelsMock: ConfigurationProviderRule {
    var configuration = SeverityLevelsConfiguration(warning: 2, error: 3)

    static let description = RuleDescription(identifier: "severity_level_mock",
                                             name: "",
                                             description: "",
                                             kind: .style,
                                             deprecatedAliases: ["mock"])

    init() {}
    init(configuration: Any) throws {
        self.init()
        try self.configuration.apply(configuration: configuration)
    }

    func validate(file: SwiftLintFile) -> [StyleViolation] { return [] }
}

class RuleTests: SwiftLintTestCase {
    fileprivate struct RuleMock1: Rule {
        var configurationDescription: String { return "N/A" }
        static let description = RuleDescription(identifier: "RuleMock1", name: "",
                                                 description: "", kind: .style)

        init() {}
        init(configuration: Any) throws { self.init() }

        func validate(file: SwiftLintFile) -> [StyleViolation] {
            return []
        }
    }

    fileprivate struct RuleMock2: Rule {
        var configurationDescription: String { return "N/A" }
        static let description = RuleDescription(identifier: "RuleMock2", name: "",
                                                 description: "", kind: .style)

        init() {}
        init(configuration: Any) throws { self.init() }

        func validate(file: SwiftLintFile) -> [StyleViolation] {
            return []
        }
    }

    fileprivate struct RuleWithLevelsMock2: ConfigurationProviderRule {
        var configuration = SeverityLevelsConfiguration(warning: 2, error: 3)

        static let description = RuleDescription(identifier: "violation_level_mock2",
                                                 name: "",
                                                 description: "", kind: .style)

        init() {}
        init(configuration: Any) throws {
            self.init()
            try self.configuration.apply(configuration: configuration)
        }

        func validate(file: SwiftLintFile) -> [StyleViolation] { return [] }
    }

    func testRuleIsEqualTo() {
        XCTAssertTrue(RuleMock1().isEqualTo(RuleMock1()))
    }

    func testRuleIsNotEqualTo() {
        XCTAssertFalse(RuleMock1().isEqualTo(RuleMock2()))
    }

    func testRuleArraysWithDifferentCountsNotEqual() {
        XCTAssertFalse([RuleMock1(), RuleMock2()] == [RuleMock1()])
    }

    func testSeverityLevelRuleInitsWithConfigDictionary() {
        let config = ["warning": 17, "error": 7]
        let rule = try? RuleWithLevelsMock(configuration: config)
        var comp = RuleWithLevelsMock()
        comp.configuration.warning = 17
        comp.configuration.error = 7
        XCTAssertEqual(rule?.isEqualTo(comp), true)
    }

    func testSeverityLevelRuleInitsWithWarningOnlyConfigDictionary() {
        let config = ["warning": 17]
        let rule = try? RuleWithLevelsMock(configuration: config)
        var comp = RuleWithLevelsMock()
        comp.configuration.warning = 17
        comp.configuration.error = nil
        XCTAssertEqual(rule?.isEqualTo(comp), true)
    }

    func testSeverityLevelRuleInitsWithErrorOnlyConfigDictionary() {
        let config = ["error": 17]
        let rule = try? RuleWithLevelsMock(configuration: config)
        var comp = RuleWithLevelsMock()
        comp.configuration.error = 17
        XCTAssertEqual(rule?.isEqualTo(comp), true)
    }

    func testSeverityLevelRuleInitsWithConfigArray() {
        let config = [17, 7] as Any
        let rule = try? RuleWithLevelsMock(configuration: config)
        var comp = RuleWithLevelsMock()
        comp.configuration.warning = 17
        comp.configuration.error = 7
        XCTAssertEqual(rule?.isEqualTo(comp), true)
    }

    func testSeverityLevelRuleInitsWithSingleValueConfigArray() {
        let config = [17] as Any
        let rule = try? RuleWithLevelsMock(configuration: config)
        var comp = RuleWithLevelsMock()
        comp.configuration.warning = 17
        comp.configuration.error = nil
        XCTAssertEqual(rule?.isEqualTo(comp), true)
    }

    func testSeverityLevelRuleInitsWithLiteral() {
        let config = 17 as Any
        let rule = try? RuleWithLevelsMock(configuration: config)
        var comp = RuleWithLevelsMock()
        comp.configuration.warning = 17
        comp.configuration.error = nil
        XCTAssertEqual(rule?.isEqualTo(comp), true)
    }

    func testSeverityLevelRuleNotEqual() {
        let config = 17 as Any
        let rule = try? RuleWithLevelsMock(configuration: config)
        XCTAssertEqual(rule?.isEqualTo(RuleWithLevelsMock()), false)
    }

    func testDifferentSeverityLevelRulesNotEqual() {
        XCTAssertFalse(RuleWithLevelsMock().isEqualTo(RuleWithLevelsMock2()))
    }
}
