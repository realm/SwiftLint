@testable import swiftlint
@_spi(TestHelper)
import SwiftLintFramework
import XCTest

final class RulesFilterTests: XCTestCase {
    func testRulesFilterExcludesEnabledRules() {
        let allRules = RuleList(
            rules: [
                RuleMock1.self,
                RuleMock2.self,
                CorrectableRuleMock.self
            ]
        )
        let enabledRules: [Rule] = [
            RuleMock1(),
            CorrectableRuleMock()
        ]
        let rulesFilter = RulesFilter(
            allRules: allRules,
            enabledRules: enabledRules
        )

        let filteredRules = rulesFilter.getRules(excluding: [.enabled])

        XCTAssertEqual(
            Set(filteredRules.list.keys),
            Set([RuleMock2.description.identifier])
        )
    }

    func testRulesFilterExcludesDisabledRules() {
        let allRules = RuleList(
            rules: [
                RuleMock1.self,
                RuleMock2.self,
                CorrectableRuleMock.self
            ]
        )
        let enabledRules: [Rule] = [
            RuleMock1(),
            CorrectableRuleMock()
        ]
        let rulesFilter = RulesFilter(
            allRules: allRules,
            enabledRules: enabledRules
        )

        let filteredRules = rulesFilter.getRules(excluding: [.disabled])

        XCTAssertEqual(
            Set(filteredRules.list.keys),
            Set([RuleMock1.description.identifier, CorrectableRuleMock.description.identifier])
        )
    }

    func testRulesFilterExcludesUncorrectableRules() {
        let allRules = RuleList(
            rules: [
                RuleMock1.self,
                RuleMock2.self,
                CorrectableRuleMock.self
            ]
        )
        let enabledRules: [Rule] = [
            RuleMock1(),
            CorrectableRuleMock()
        ]
        let rulesFilter = RulesFilter(
            allRules: allRules,
            enabledRules: enabledRules
        )

        let filteredRules = rulesFilter.getRules(excluding: [.uncorrectable])

        XCTAssertEqual(
            Set(filteredRules.list.keys),
            Set([CorrectableRuleMock.description.identifier])
        )
    }

    func testRulesFilterExcludesUncorrectableDisabledRules() {
        let allRules = RuleList(
            rules: [
                RuleMock1.self,
                RuleMock2.self,
                CorrectableRuleMock.self
            ]
        )
        let enabledRules: [Rule] = [
            RuleMock1(),
            CorrectableRuleMock()
        ]
        let rulesFilter = RulesFilter(
            allRules: allRules,
            enabledRules: enabledRules
        )

        let filteredRules = rulesFilter.getRules(excluding: [.disabled, .uncorrectable])

        XCTAssertEqual(
            Set(filteredRules.list.keys),
            Set([CorrectableRuleMock.description.identifier])
        )
    }

    func testRulesFilterExcludesUncorrectableEnabledRules() {
        let allRules = RuleList(
            rules: [
                RuleMock1.self,
                RuleMock2.self,
                CorrectableRuleMock.self
            ]
        )
        let enabledRules: [Rule] = [
            RuleMock1()
        ]
        let rulesFilter = RulesFilter(
            allRules: allRules,
            enabledRules: enabledRules
        )

        let filteredRules = rulesFilter.getRules(excluding: [.enabled, .uncorrectable])

        XCTAssertEqual(
            Set(filteredRules.list.keys),
            Set([CorrectableRuleMock.description.identifier])
        )
    }
}

// MARK: - Mocks

private struct RuleMock1: Rule {
    var configurationDescription: String { return "N/A" }
    static let description = RuleDescription(identifier: "RuleMock1", name: "",
                                             description: "", kind: .style)

    init() {}
    init(configuration: Any) throws { self.init() }

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        return []
    }
}

private struct RuleMock2: Rule {
    var configurationDescription: String { return "N/A" }
    static let description = RuleDescription(identifier: "RuleMock2", name: "",
                                             description: "", kind: .style)

    init() {}
    init(configuration: Any) throws { self.init() }

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        return []
    }
}

private struct CorrectableRuleMock: CorrectableRule {
    var configurationDescription: String { return "N/A" }
    static let description = RuleDescription(identifier: "CorrectableRuleMock", name: "",
                                             description: "", kind: .style)

    init() {}
    init(configuration: Any) throws { self.init() }

    func validate(file: SwiftLintFile) -> [StyleViolation] {
        return []
    }

    func correct(file: SwiftLintFile) -> [Correction] {
        []
    }
}
