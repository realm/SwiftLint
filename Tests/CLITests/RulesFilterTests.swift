import SwiftLintFramework
import XCTest

final class RulesFilterTests: XCTestCase {
    func testRulesFilterExcludesEnabledRules() {
        let allRules = RuleList(
            rules: [
                RuleMock1.self,
                RuleMock2.self,
                CorrectableRuleMock.self,
            ]
        )
        let enabledRules: [any Rule] = [
            RuleMock1(),
            CorrectableRuleMock(),
        ]
        let rulesFilter = RulesFilter(
            allRules: allRules,
            enabledRules: enabledRules
        )

        let filteredRules = rulesFilter.getRules(excluding: [.enabled])

        XCTAssertEqual(
            Set(filteredRules.list.keys),
            Set([RuleMock2.identifier])
        )
    }

    func testRulesFilterExcludesDisabledRules() {
        let allRules = RuleList(
            rules: [
                RuleMock1.self,
                RuleMock2.self,
                CorrectableRuleMock.self,
            ]
        )
        let enabledRules: [any Rule] = [
            RuleMock1(),
            CorrectableRuleMock(),
        ]
        let rulesFilter = RulesFilter(
            allRules: allRules,
            enabledRules: enabledRules
        )

        let filteredRules = rulesFilter.getRules(excluding: [.disabled])

        XCTAssertEqual(
            Set(filteredRules.list.keys),
            Set([RuleMock1.identifier, CorrectableRuleMock.identifier])
        )
    }

    func testRulesFilterExcludesUncorrectableRules() {
        let allRules = RuleList(
            rules: [
                RuleMock1.self,
                RuleMock2.self,
                CorrectableRuleMock.self,
            ]
        )
        let enabledRules: [any Rule] = [
            RuleMock1(),
            CorrectableRuleMock(),
        ]
        let rulesFilter = RulesFilter(
            allRules: allRules,
            enabledRules: enabledRules
        )

        let filteredRules = rulesFilter.getRules(excluding: [.uncorrectable])

        XCTAssertEqual(
            Set(filteredRules.list.keys),
            Set([CorrectableRuleMock.identifier])
        )
    }

    func testRulesFilterExcludesUncorrectableDisabledRules() {
        let allRules = RuleList(
            rules: [
                RuleMock1.self,
                RuleMock2.self,
                CorrectableRuleMock.self,
            ]
        )
        let enabledRules: [any Rule] = [
            RuleMock1(),
            CorrectableRuleMock(),
        ]
        let rulesFilter = RulesFilter(
            allRules: allRules,
            enabledRules: enabledRules
        )

        let filteredRules = rulesFilter.getRules(excluding: [.disabled, .uncorrectable])

        XCTAssertEqual(
            Set(filteredRules.list.keys),
            Set([CorrectableRuleMock.identifier])
        )
    }

    func testRulesFilterExcludesUncorrectableEnabledRules() {
        let allRules = RuleList(
            rules: [
                RuleMock1.self,
                RuleMock2.self,
                CorrectableRuleMock.self,
            ]
        )
        let enabledRules: [any Rule] = [
            RuleMock1()
        ]
        let rulesFilter = RulesFilter(
            allRules: allRules,
            enabledRules: enabledRules
        )

        let filteredRules = rulesFilter.getRules(excluding: [.enabled, .uncorrectable])

        XCTAssertEqual(
            Set(filteredRules.list.keys),
            Set([CorrectableRuleMock.identifier])
        )
    }
}

// MARK: - Mocks

private struct RuleMock1: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)
    var configurationDescription: some Documentable { RuleConfigurationOption.noOptions }

    static let description = RuleDescription(identifier: "RuleMock1", name: "",
                                             description: "", kind: .style)

    init() { /* conformance for test */ }
    init(configuration _: Any) throws { self.init() }

    func validate(file _: SwiftLintFile) -> [StyleViolation] {
        []
    }
}

private struct RuleMock2: Rule {
    var configuration = SeverityConfiguration<Self>(.warning)
    var configurationDescription: some Documentable { RuleConfigurationOption.noOptions }

    static let description = RuleDescription(identifier: "RuleMock2", name: "",
                                             description: "", kind: .style)

    init() { /* conformance for test */ }
    init(configuration _: Any) throws { self.init() }

    func validate(file _: SwiftLintFile) -> [StyleViolation] {
        []
    }
}

private struct CorrectableRuleMock: CorrectableRule {
    var configuration = SeverityConfiguration<Self>(.warning)
    var configurationDescription: some Documentable { RuleConfigurationOption.noOptions }

    static let description = RuleDescription(identifier: "CorrectableRuleMock", name: "",
                                             description: "", kind: .style)

    init() { /* conformance for test */ }
    init(configuration _: Any) throws { self.init() }

    func validate(file _: SwiftLintFile) -> [StyleViolation] {
        []
    }

    func correct(file _: SwiftLintFile) -> [Correction] {
        []
    }
}
