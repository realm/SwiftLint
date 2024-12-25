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
        testCoverageWithDisabledIdentifiers(disabledIdentifiers: ["all"], observedCoverage: 4, maximumCoverage: 40)
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
            disabledIdentifiers: ["all"],
            observedCoverage: 3,
            maximumCoverage: 30
        )

        func testDisablingAllCustomRules(disabledIdentifiers: [String]) {
            testCoverageWithDisabledIdentifiers(
                for: rules,
                disabledIdentifiers: disabledIdentifiers,
                observedCoverage: 12,
                maximumCoverage: 30
            )
        }

        let customRulesIdentifier = CustomRules.identifier
        testDisablingAllCustomRules(disabledIdentifiers: [customRulesIdentifier])
        let firstCustomRuleIdentifier = customRules.customRuleIdentifiers[0]
        testDisablingAllCustomRules(disabledIdentifiers: [customRulesIdentifier, firstCustomRuleIdentifier])
        let secondCustomRuleIdentifier = customRules.customRuleIdentifiers[1]
        testDisablingAllCustomRules(disabledIdentifiers: [customRulesIdentifier, secondCustomRuleIdentifier])
        testDisablingAllCustomRules(
            disabledIdentifiers: [customRulesIdentifier, firstCustomRuleIdentifier, secondCustomRuleIdentifier]
        )
        testDisablingAllCustomRules(disabledIdentifiers: [firstCustomRuleIdentifier, secondCustomRuleIdentifier])

        testCoverageWithDisabledIdentifiers(
            for: rules,
            disabledIdentifiers: [firstCustomRuleIdentifier],
            observedCoverage: 21,
            maximumCoverage: 30
        )

        testCoverageWithDisabledIdentifiers(
            for: rules,
            disabledIdentifiers: [secondCustomRuleIdentifier],
            observedCoverage: 21,
            maximumCoverage: 30
        )
    }

    // MARK: - Private
    private func testCoverage(
        for rules: [any Rule] = CoverageTests.rules,
        source: String,
        observedCoverage: Int = 0,
        maximumCoverage: Int = 0
    )
    {
        let file = SwiftLintFile(contents: source)
        let numberOfLinesOfCode = file.contents.isEmpty ? 0 : file.lines.count
        let expectedCoverage = Coverage.Coverage(
            numberOfLinesOfCode: numberOfLinesOfCode,
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
