@testable import SwiftLintBuiltInRules
@testable import SwiftLintCore
@testable import SwiftLintFramework
import XCTest

final class CoverageTests: SwiftLintTestCase {
    private typealias Configuration = RegexConfiguration<CustomRules>

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
            disabledIdentifiersString: "all",
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
    }

    func testCoverageWithCustomRules() {
        let customRules = customRules()
        let rules: [any Rule] = [customRules, ArrayInitRule()]

        func testCoverage(
            totalNumberOfRules: Int = 3,
            disabledIdentifiersString: String,
            enabledRulesCoverage: String,
            allRulesCoverage: String
        ) {
            testCoverageWithDisabledIdentifiers(
                for: rules,
                totalNumberOfRules: totalNumberOfRules,
                disabledIdentifiersString: disabledIdentifiersString,
                enabledRulesCoverage: enabledRulesCoverage,
                allRulesCoverage: allRulesCoverage
            )
        }

        testCoverage(disabledIdentifiersString: "all", enabledRulesCoverage: "0.1", allRulesCoverage: "0.1")
        testCoverage(disabledIdentifiersString: "custom_rules", enabledRulesCoverage: "0.4", allRulesCoverage: "0.4")

        let firstCustomRuleIdentifier = customRules.customRuleIdentifiers[0]
        testCoverage(
            disabledIdentifiersString: "custom_rules \(firstCustomRuleIdentifier)",
            enabledRulesCoverage: "0.4",
            allRulesCoverage: "0.4"
        )
        let secondCustomRuleIdentifier = customRules.customRuleIdentifiers[1]
        testCoverage(
            disabledIdentifiersString: "custom_rules \(secondCustomRuleIdentifier)",
            enabledRulesCoverage: "0.4",
            allRulesCoverage: "0.4"
        )
        testCoverage(
            disabledIdentifiersString: "custom_rules \(firstCustomRuleIdentifier) \(secondCustomRuleIdentifier)",
            enabledRulesCoverage: "0.4",
            allRulesCoverage: "0.4"
        )
        testCoverage(
            disabledIdentifiersString: "\(firstCustomRuleIdentifier) \(secondCustomRuleIdentifier)",
            enabledRulesCoverage: "0.4",
            allRulesCoverage: "0.4"
        )

        testCoverage(
            disabledIdentifiersString: "\(firstCustomRuleIdentifier)",
            enabledRulesCoverage: "0.7",
            allRulesCoverage: "0.7"
        )

        testCoverage(
            disabledIdentifiersString: "\(secondCustomRuleIdentifier)",
            enabledRulesCoverage: "0.7",
            allRulesCoverage: "0.7"
        )

        testCoverage(
            totalNumberOfRules: 10,
            disabledIdentifiersString: "\(secondCustomRuleIdentifier)",
            enabledRulesCoverage: "0.7",
            allRulesCoverage: "0.21"
        )
    }

    // MARK: - Private
    private func testCoverageWithDisabledIdentifiers(
        for rules: [any Rule] = CoverageTests.rules,
        totalNumberOfRules: Int = CoverageTests.totalNumberOfRules,
        disabledIdentifiersString: String,
        enabledRulesCoverage: String,
        allRulesCoverage: String
    ) {
        let filler = String(repeating: "\n", count: 10)
        testCoverage(
            for: rules,
            totalNumberOfRules: totalNumberOfRules,
            source: "// swiftlint:disable \(disabledIdentifiersString)" + filler,
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

    private func customRules() -> CustomRules {
        func configuration(withIdentifier identifier: String, configurationDict: [String: Any]) -> Configuration {
            var regexConfig = Configuration(identifier: identifier)
            do {
                try regexConfig.apply(configuration: configurationDict)
            } catch {
                XCTFail("Failed regex config")
            }
            return regexConfig
        }

        let customRuleConfiguration = CustomRulesConfiguration(customRuleConfigurations: [
            configuration(withIdentifier: "custom1", configurationDict: ["regex": "pattern"]),
            configuration(withIdentifier: "custom2", configurationDict: ["regex": "something"]),
        ])
        return CustomRules(configuration: customRuleConfiguration)
    }
}

private extension String {
    func replacingLastLine(with string: String) -> String {
        components(separatedBy: "\n").dropLast().joined(separator: "\n") + "\n\(string)"
    }
}
