@testable import SwiftLintBuiltInRules
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
        testCoverage(
            source: "",
            enabledRulesCoverage: "1.0",
            allRulesCoverage: "0.4"
        )
    }

    func testNoDisabledCommandCoverage() {
        let source = """
             func foo() -> Int {
                 return 0
             }
             """

        testCoverage(
            source: source,
            enabledRulesCoverage: "1.0",
            allRulesCoverage: "0.4"
        )
    }

    func testCoverageWithRegions() {
        let sourceWithRegionsForEnabledRulesOnly = """
             func foo() -> Int {
                 // swiftlint:disable:next direct_return
                 return 0
             }

             // These blank lines keep the linecount consistent
             """

        let expectedEnabledRulesCoverage = "0.958"
        let expectedAllRulesCoverage = "0.383"

        testCoverage(
            source: sourceWithRegionsForEnabledRulesOnly,
            enabledRulesCoverage: expectedEnabledRulesCoverage,
            allRulesCoverage: expectedAllRulesCoverage
        )

        let sourceWithRegionsForIrrelevantRules = sourceWithRegionsForEnabledRulesOnly
            .components(separatedBy: "\n")
            .dropLast()
            .joined(separator: "\n")
            + ("\n// swiftlint:disable:previous expiring_todo")

        testCoverage(
            source: sourceWithRegionsForIrrelevantRules,
            enabledRulesCoverage: expectedEnabledRulesCoverage,
            allRulesCoverage: expectedAllRulesCoverage
        )
    }

    func testDisableAllCoverage() {
        let source = "// swiftlint:disable all".appending(String(repeating: "\n", count: 10))
        // The `swiftlint:disable` line will still be linted, so coverage will not be zero.
        testCoverage(source: source, enabledRulesCoverage: "0.1", allRulesCoverage: "0.04")
    }

    private func testCoverage(
        for rules: [any Rule] = CoverageTests.rules,
        totalNumberOfRules: Int = CoverageTests.totalNumberOfRules,
        source: String,
        enabledRulesCoverage: String,
        allRulesCoverage: String
    ) {
        var coverage = Coverage(totalNumberOfRules: totalNumberOfRules)
        XCTAssertEqual(coverage.enabledRulesCoverage, 0)
        XCTAssertEqual(coverage.allRulesCoverage, 0)
        let file = SwiftLintFile(contents: source)
        coverage.addCoverage(for: file, rules: rules)
        XCTAssertEqual(coverage.report, """
                                        Enabled rules coverage: \(enabledRulesCoverage)
                                            All rules coverage: \(allRulesCoverage)
                                        """)
    }
}
