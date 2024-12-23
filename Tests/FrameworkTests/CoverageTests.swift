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
        testCoverage(
            source: "",
            enabledRulesCoverage: "0.0",
            allRulesCoverage: "0.0"
        )
    }

    func testBlankLineSourceCoverage() {
        testCoverage(
            source: "\n",
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
        // The `disable` command line will still be linted, so coverage will not be zero.
        testCoverage(source: source, enabledRulesCoverage: "0.1", allRulesCoverage: "0.04")
    }

    func testCoverageWithCustomRules() {
        let customRules = customRules()
        let filler = String(repeating: "\n", count: 10)
        let sourceDisablingAllCustomRules = "// swiftlint:disable custom_rules" + filler
        testCoverage(
            for: [customRules],
            totalNumberOfRules: 2,
            source: sourceDisablingAllCustomRules,
            enabledRulesCoverage: "0.1",
            allRulesCoverage: "0.1"
        )

        func testDisablingOneCustomRule(_ i: Int, totalNumberOfRules: Int, allRulesCoverage: String) {
            let sourceDisablingOneCustomRule = "// swiftlint:disable \(customRules.customRuleIdentifiers[i])" + filler
            testCoverage(
                for: [customRules],
                totalNumberOfRules: totalNumberOfRules,
                source: sourceDisablingOneCustomRule,
                enabledRulesCoverage: "0.55",
                allRulesCoverage: allRulesCoverage
            )
        }
        testDisablingOneCustomRule(0, totalNumberOfRules: 2, allRulesCoverage: "0.55")
        testDisablingOneCustomRule(1, totalNumberOfRules: 2, allRulesCoverage: "0.55")
        testDisablingOneCustomRule(1, totalNumberOfRules: 10, allRulesCoverage: "0.11")
    }

    // MARK: - Private
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

        let regexConfig1 = configuration(withIdentifier: "custom1", configurationDict: ["regex": "pattern"])
        let regexConfig2 = configuration(withIdentifier: "custom2", configurationDict: ["regex": "something"])
        let customRuleConfiguration = CustomRulesConfiguration(customRuleConfigurations: [regexConfig1, regexConfig2])
        return CustomRules(configuration: customRuleConfiguration)
    }
}
