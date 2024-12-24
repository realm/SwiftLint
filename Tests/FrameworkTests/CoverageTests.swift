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
        testCoverage(source: "", enabledRulesCoverage: "0.0", allRulesCoverage: "0.0")
    }

    func testBlankLineSourceCoverage() {
        testCoverage(source: "\n", enabledRulesCoverage: "1.0", allRulesCoverage: "0.4")
    }

    func testNoRulesCoverage() {
        testCoverage(
            for: [],
            totalNumberOfRules: 0,
            source: "\n",
            enabledRulesCoverage: "0.0",
            allRulesCoverage: "0.0"
        )
    }

    func testNoDisabledCommandCoverage() {
        let source = """
             func foo() -> Int {
                 return 0
             }
             """

        testCoverage(source: source, enabledRulesCoverage: "1.0", allRulesCoverage: "0.4")
    }

    func testDisableAllCoverage() {
        // The `disable` command line will still be linted, so coverage will not be zero.
        testCoverageWithDisabledIdentifiers(
            disabledIdentifiers: ["all"],
            enabledRulesCoverage: "0.1",
            allRulesCoverage: "0.04"
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

        let expectedEnabledRulesCoverage = "0.958"
        let expectedAllRulesCoverage = "0.383"

        testCoverage(
            source: enabledRuleRegionSource,
            enabledRulesCoverage: expectedEnabledRulesCoverage,
            allRulesCoverage: expectedAllRulesCoverage
        )

        let irrelevantRegionsSource = enabledRuleRegionSource.replacingLastLine(
            with: "// swiftlint:disable:previous expiring_todo"
        )

        testCoverage(
            source: irrelevantRegionsSource,
            enabledRulesCoverage: expectedEnabledRulesCoverage,
            allRulesCoverage: expectedAllRulesCoverage
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
            enabledRulesCoverage: expectedEnabledRulesCoverage,
            allRulesCoverage: expectedAllRulesCoverage
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
            enabledRulesCoverage: "0.688",
            allRulesCoverage: "0.413"
        )
    }

    func testCoverageWithCustomRules() throws {
        let customRules = try customRules()
        let rules: [any Rule] = [customRules, ArrayInitRule()]

        func testCoverage(
            totalNumberOfRules: Int = 3,
            disabledIdentifiers: [String],
            enabledRulesCoverage: String,
            allRulesCoverage: String
        ) {
            testCoverageWithDisabledIdentifiers(
                for: rules,
                totalNumberOfRules: totalNumberOfRules,
                disabledIdentifiers: disabledIdentifiers,
                enabledRulesCoverage: enabledRulesCoverage,
                allRulesCoverage: allRulesCoverage
            )
        }

        testCoverage(disabledIdentifiers: ["all"], enabledRulesCoverage: "0.1", allRulesCoverage: "0.1")

        func testDisablingAllCustomRules(disabledIdentifiers: [String]) {
            testCoverage(
                disabledIdentifiers: disabledIdentifiers,
                enabledRulesCoverage: "0.4",
                allRulesCoverage: "0.4"
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

        testCoverage(
            disabledIdentifiers: [firstCustomRuleIdentifier],
            enabledRulesCoverage: "0.7",
            allRulesCoverage: "0.7"
        )

        testCoverage(
            disabledIdentifiers: [secondCustomRuleIdentifier],
            enabledRulesCoverage: "0.7",
            allRulesCoverage: "0.7"
        )

        testCoverage(
            totalNumberOfRules: 10,
            disabledIdentifiers: [secondCustomRuleIdentifier],
            enabledRulesCoverage: "0.7",
            allRulesCoverage: "0.21"
        )
    }

    // MARK: - Private
    private func testCoverageWithDisabledIdentifiers(
        for rules: [any Rule] = CoverageTests.rules,
        totalNumberOfRules: Int = CoverageTests.totalNumberOfRules,
        disabledIdentifiers: [String],
        enabledRulesCoverage: String,
        allRulesCoverage: String
    ) {
        let filler = String(repeating: "\n", count: 10)
        testCoverage(
            for: rules,
            totalNumberOfRules: totalNumberOfRules,
            source: "// swiftlint:disable \(disabledIdentifiers.joined(separator: " "))" + filler,
            enabledRulesCoverage: enabledRulesCoverage,
            allRulesCoverage: allRulesCoverage
        )
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
