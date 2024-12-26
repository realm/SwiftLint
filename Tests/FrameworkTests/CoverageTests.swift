@testable import SwiftLintBuiltInRules
@testable import SwiftLintCore
@testable import SwiftLintFramework
import XCTest

final class CoverageTests: SwiftLintTestCase {
    private static let ruleIdentifiers: [String] = [
        ArrayInitRule.identifier,
        BlockBasedKVORule.identifier,
        ClosingBraceRule.identifier,
        DirectReturnRule.identifier,
    ]

    private static let customRuleIdentifier1 = "custom1"
    private static let customRuleIdentifier2 = "custom2"
    private static let customRulesConfiguration = [
        customRuleIdentifier1: ["regex": "pattern"],
        customRuleIdentifier2: ["regex": "something"],
    ]

    func testEmptySourceCoverage() throws {
        try testCoverage(source: "")
    }

    func testBlankLineSourceCoverage() throws {
        try testCoverage(source: "\n")
        try testCoverage(source: "\n\n", observedCoverage: 8, maximumCoverage: 8)
    }

    func testNoRulesCoverage() throws {
        try testCoverage(for: [], source: "\n")
    }

    func testNoDisabledCommandCoverage() throws {
        let source = """
             func foo() -> Int {
                 return 0
             }
             """

        try testCoverage(source: source, observedCoverage: 12, maximumCoverage: 12)
    }

    func testDisableAllCoverage() throws {
        // The `disable` command line will still be linted, so coverage will not be zero.
        try testCoverageWithDisabledRuleIdentifiers(
            disabledRuleIdentifiers: [RuleIdentifier.all.stringRepresentation],
            observedCoverage: 4,
            maximumCoverage: 40
        )
    }

    func testCoverageWithRegions() throws {
        let enabledRuleRegionSource = """
             func foo() -> Int {
                 // swiftlint:disable:next direct_return
                 return 0
             }

             // These blank lines keep the linecount consistent
             """

        let expectedObservedCoverage = 23
        let expectedMaximumCoverage = 24

        try testCoverage(
            source: enabledRuleRegionSource,
            observedCoverage: expectedObservedCoverage,
            maximumCoverage: expectedMaximumCoverage
        )

        let irrelevantRegionsSource = enabledRuleRegionSource.replacingLastLine(
            with: "// swiftlint:disable:previous expiring_todo"
        )

        try testCoverage(
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

        try testCoverage(
            source: overlappingRegionSource,
            observedCoverage: expectedObservedCoverage,
            maximumCoverage: expectedMaximumCoverage
        )
    }

    func testNestedAndOverlappingRegions() throws {
        let enabledRuleIdentifiers = Self.ruleIdentifiers + [CustomRules.identifier]

        let source = """
                     // swiftlint:disable \(Self.customRuleIdentifier1)
                     // swiftlint:disable array_init
                     // swiftlint:disable \(Self.customRuleIdentifier1) direct_return

                     // swiftlint:enable array_init direct_return
                     // swiftlint:enable \(Self.customRuleIdentifier2)

                     // swiftlint:enable \(Self.customRuleIdentifier1)
                     """

        try testCoverage(
            for: enabledRuleIdentifiers,
            customRules: Self.customRulesConfiguration,
            source: source,
            observedCoverage: 36, // or should it be 33?
            maximumCoverage: 48
        )
    }

    func testCoverageWithCustomRules() throws {
        let enabledRuleIdentifiers: [String] = [CustomRules.identifier, ArrayInitRule.identifier]

        try testCoverageWithDisabledRuleIdentifiers(
            for: enabledRuleIdentifiers,
            customRules: Self.customRulesConfiguration,
            disabledRuleIdentifiers: [RuleIdentifier.all.stringRepresentation],
            observedCoverage: 3,
            maximumCoverage: 30
        )

        let customRulesIdentifier = CustomRules.identifier
        let firstCustomRuleIdentifier = Self.customRuleIdentifier1
        let secondCustomRuleIdentifier = Self.customRuleIdentifier2

        let disabledRuleIdentifiers = [
            [customRulesIdentifier],
            [customRulesIdentifier, firstCustomRuleIdentifier],
            [customRulesIdentifier, secondCustomRuleIdentifier],
            [customRulesIdentifier, firstCustomRuleIdentifier, secondCustomRuleIdentifier],
            [firstCustomRuleIdentifier, secondCustomRuleIdentifier],
        ]

        try disabledRuleIdentifiers.forEach {
            try testCoverageWithDisabledRuleIdentifiers(
                for: enabledRuleIdentifiers,
                customRules: Self.customRulesConfiguration,
                disabledRuleIdentifiers: $0,
                observedCoverage: 12,
                maximumCoverage: 30
            )
        }

        try [firstCustomRuleIdentifier, secondCustomRuleIdentifier].forEach {
            try testCoverageWithDisabledRuleIdentifiers(
                for: enabledRuleIdentifiers,
                customRules: Self.customRulesConfiguration,
                disabledRuleIdentifiers: [$0],
                observedCoverage: 21,
                maximumCoverage: 30
            )
        }
    }

    func testRuleAliasesCoverage() throws {
        let enabledRuleIdentifiers = Array(Self.ruleIdentifiers.dropLast() + [ShorthandOptionalBindingRule.identifier])
        let disabledRuleIdentifiers = ShorthandOptionalBindingRule.description.allIdentifiers
        XCTAssertGreaterThan(enabledRuleIdentifiers.count, 1)
        try testCoverageWithDisabledRuleIdentifiers(
            for: enabledRuleIdentifiers,
            disabledRuleIdentifiers: disabledRuleIdentifiers,
            observedCoverage: 31,
            maximumCoverage: 40
        )
    }

    func testCoverageReport() throws {
        let source = """
             func foo() -> Int {
                 return 0 // swiftlint:disable:this direct_return
             }
             """

        let coverage = try coverage(file: SwiftLintFile(contents: source))
        let expectedReport = """
                             Enabled rules coverage: 0.917
                             """
        let report = coverage.report.components(separatedBy: "\n").dropLast().joined(separator: "\n")
        XCTAssertEqual(report, expectedReport)
    }

    // MARK: - Private
    private func testCoverage(
        for enabledRuleIdentifiers: [String] = CoverageTests.ruleIdentifiers,
        customRules: [String: [String: String]] = [:],
        source: String,
        observedCoverage: Int = 0,
        maximumCoverage: Int = 0
    ) throws {
        let file = SwiftLintFile(contents: source)
        let coverage = try coverage(
            for: enabledRuleIdentifiers,
            customRules: customRules,
            file: file
        )
        let expectedCoverage = Coverage.Coverage(
            numberOfLinesOfCode: file.isEmpty ? 0 : file.lines.count,
            observedCoverage: observedCoverage,
            maximumCoverage: maximumCoverage
        )
        XCTAssertEqual(coverage.coverage, expectedCoverage)
    }

    private func coverage(
        for enabledRuleIdentifiers: [String] = CoverageTests.ruleIdentifiers,
        customRules: [String: [String: String]] = [:],
        file: SwiftLintFile
    ) throws -> Coverage {
        let configuration = try Configuration(dict: ["only_rules": enabledRuleIdentifiers, CustomRules.identifier: customRules])
        var coverage = Coverage(mode: .lint, configuration: configuration)
        let linter = Linter(file: file, configuration: configuration)
        let collectedLinter = linter.collect(into: RuleStorage())
        coverage.addCoverage(for: collectedLinter)
        return coverage
    }

    private func testCoverageWithDisabledRuleIdentifiers(
        for enabledRuleIdentifiers: [String] = CoverageTests.ruleIdentifiers,
        customRules: [String: [String: String]] = [:],
        disabledRuleIdentifiers: [String],
        observedCoverage: Int,
        maximumCoverage: Int
    ) throws {
        let filler = String(repeating: "\n", count: 10)
        try testCoverage(
            for: enabledRuleIdentifiers,
            customRules: customRules,
            source: "// swiftlint:disable \(disabledRuleIdentifiers.joined(separator: " "))" + filler,
            observedCoverage: observedCoverage,
            maximumCoverage: maximumCoverage
        )
    }
}

private extension String {
    func replacingLastLine(with string: String) -> String {
        components(separatedBy: "\n").dropLast().joined(separator: "\n") + "\n\(string)"
    }
}
