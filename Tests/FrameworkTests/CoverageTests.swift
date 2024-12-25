@testable import SwiftLintBuiltInRules
@testable import SwiftLintCore
@testable import SwiftLintFramework
import XCTest

final class CoverageTests: SwiftLintTestCase {
    private static let rules: [any Rule] = [
        ArrayInitRule(),
        BlockBasedKVORule(),
        ClosingBraceRule(),
        DirectReturnRule(),
    ]

    private static let totalNumberOfRules = 10

    func testEmptySourceCoverage() {
        testCoverage(source: "")
    }

    func testBlankLineSourceCoverage() {
        testCoverage(source: "\n", observedCoverage: 4, maximumCoverage: 4)
    }

    func testNoRulesCoverage() {
        testCoverage(for: [], source: "\n")
    }

    func testNoDisabledCommandCoverage() {
        let source = """
             func foo() -> Int {
                 return 0
             }
             """

        testCoverage(source: source, observedCoverage: 12, maximumCoverage: 12)
    }

    func testDisableAllCoverage() {
        // The `disable` command line will still be linted, so coverage will not be zero.
        testCoverageWithDisabledIdentifiers(
            disabledIdentifiers: [RuleIdentifier.all.stringRepresentation],
            observedCoverage: 4,
            maximumCoverage: 40
        )
    }

    func testCoverageWithRegions() {
        let enabledRuleRegionSource = """
             func foo() -> Int {
                 // swiftlint:disable:next direct_return
                 return 0
             }

             // These blank lines keep the linecount consistent
             """

        let expectedObservedCoverage = 23
        let expectedMaximumCoverage = 24

        testCoverage(
            source: enabledRuleRegionSource,
            observedCoverage: expectedObservedCoverage,
            maximumCoverage: expectedMaximumCoverage
        )

        let irrelevantRegionsSource = enabledRuleRegionSource.replacingLastLine(
            with: "// swiftlint:disable:previous expiring_todo"
        )

        testCoverage(
            source: irrelevantRegionsSource,
            observedCoverage: expectedObservedCoverage,
            maximumCoverage: expectedMaximumCoverage
        )

        let overlappingRegionSource = """
             func foo() -> Int {
                 // swiftlint:disable:next direct_return
                 return 0 // swiftlint:disable:this direct_return
             } // swiftlint:disable:previous direct_return

             // These blank lines keep the linecount consistent
             """

        testCoverage(
            source: overlappingRegionSource,
            observedCoverage: expectedObservedCoverage,
            maximumCoverage: expectedMaximumCoverage
        )
    }

    func testNestedAndOverlappingRegions() throws {
        let customRules = try customRules()
        let rules: [any Rule] = [customRules] + Self.rules

        let source = """
                     // swiftlint:disable \(customRules.customRuleIdentifiers[0])
                     // swiftlint:disable array_init
                     // swiftlint:disable \(customRules.customRuleIdentifiers[1]) direct_return

                     // swiftlint:enable array_init direct_return
                     // swiftlint:enable \(customRules.customRuleIdentifiers[1])

                     // swiftlint:enable \(customRules.customRuleIdentifiers[0])
                     """

        testCoverage(
            for: rules,
            source: source,
            observedCoverage: 33,
            maximumCoverage: 48
        )
    }

    func testCoverageWithCustomRules() throws {
        let customRules = try customRules()
        let rules: [any Rule] = [customRules, ArrayInitRule()]

        testCoverageWithDisabledIdentifiers(
            for: rules,
            disabledIdentifiers: [RuleIdentifier.all.stringRepresentation],
            observedCoverage: 3,
            maximumCoverage: 30
        )

        let customRulesIdentifier = CustomRules.identifier
        let firstCustomRuleIdentifier = customRules.customRuleIdentifiers[0]
        let secondCustomRuleIdentifier = customRules.customRuleIdentifiers[1]

        let disabledRuleIdentifiers = [
            [customRulesIdentifier],
            [customRulesIdentifier, firstCustomRuleIdentifier],
            [customRulesIdentifier, secondCustomRuleIdentifier],
            [customRulesIdentifier, firstCustomRuleIdentifier, secondCustomRuleIdentifier],
            [firstCustomRuleIdentifier, secondCustomRuleIdentifier],
        ]

        disabledRuleIdentifiers.forEach {
            testCoverageWithDisabledIdentifiers(
                for: rules,
                disabledIdentifiers: $0,
                observedCoverage: 12,
                maximumCoverage: 30
            )
        }

        [firstCustomRuleIdentifier, secondCustomRuleIdentifier].forEach {
            testCoverageWithDisabledIdentifiers(
                for: rules,
                disabledIdentifiers: [$0],
                observedCoverage: 21,
                maximumCoverage: 30
            )
        }
    }

    func testRuleAliasesCoverage() {
        let rules: [any Rule] = Self.rules.dropLast() + [ShorthandOptionalBindingRule()]
        let ruleIdentifiers = ShorthandOptionalBindingRule.description.allIdentifiers
        XCTAssertGreaterThan(ruleIdentifiers.count, 1)
        testCoverageWithDisabledIdentifiers(
            for: rules,
            disabledIdentifiers: ruleIdentifiers,
            observedCoverage: 31,
            maximumCoverage: 40
        )
    }

    func testCoverageReport() {
        let source = """
             func foo() -> Int {
                 return 0 // swiftlint:disable:this direct_return
             }
             """

        var coverage = Coverage(totalNumberOfRules: 10)
        coverage.addCoverage(for: SwiftLintFile(contents: source), rules: Self.rules)
        let expectedReport = """
                             Enabled rules coverage: 0.917
                                 All rules coverage: 0.367
                             """
        XCTAssertEqual(coverage.report, expectedReport)
    }

    // MARK: - Private
    private func testCoverage(
        for rules: [any Rule] = CoverageTests.rules,
        source: String,
        observedCoverage: Int = 0,
        maximumCoverage: Int = 0
    ) {
        let file = SwiftLintFile(contents: source)
        let expectedCoverage = Coverage.Coverage(
            numberOfLinesOfCode: file.contents.isEmpty ? 0 : file.lines.count,
            observedCoverage: observedCoverage,
            maximumCoverage: maximumCoverage
        )
        var coverage = Coverage(totalNumberOfRules: 10)
        coverage.addCoverage(for: file, rules: rules)
        XCTAssertEqual(coverage.coverage, expectedCoverage)
    }

    private func testCoverageWithDisabledIdentifiers(
        for rules: [any Rule] = CoverageTests.rules,
        disabledIdentifiers: [String],
        observedCoverage: Int,
        maximumCoverage: Int
    ) {
        let filler = String(repeating: "\n", count: 10)
        testCoverage(
            for: rules,
            source: "// swiftlint:disable \(disabledIdentifiers.joined(separator: " "))" + filler,
            observedCoverage: observedCoverage,
            maximumCoverage: maximumCoverage
        )
    }

    private func customRules() throws -> CustomRules {
        func configuration(
            withIdentifier identifier: String,
            configurationDict: [String: Any]
        ) throws -> RegexConfiguration<CustomRules> {
            var regexConfig = RegexConfiguration<CustomRules>(identifier: identifier)
            try regexConfig.apply(configuration: configurationDict)
            return regexConfig
        }
        let customRuleConfiguration = CustomRulesConfiguration(customRuleConfigurations: [
            try configuration(withIdentifier: "custom1", configurationDict: ["regex": "pattern"]),
            try configuration(withIdentifier: "custom2", configurationDict: ["regex": "something"]),
        ])
        return CustomRules(configuration: customRuleConfiguration)
    }
}

private extension String {
    func replacingLastLine(with string: String) -> String {
        components(separatedBy: "\n").dropLast().joined(separator: "\n") + "\n\(string)"
    }
}
