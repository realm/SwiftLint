import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct CyclomaticComplexityConfigurationTests {
    @Test
    func cyclomaticComplexityConfigurationInitializerSetsLevels() {
        let warning = 10
        let error = 30
        let level = SeverityLevelsConfiguration<CyclomaticComplexityRule>(warning: warning, error: error)
        let configuration1 = CyclomaticComplexityConfiguration(length: level)
        #expect(configuration1.length == level)

        let length2 = SeverityLevelsConfiguration<CyclomaticComplexityRule>(warning: warning, error: nil)
        let configuration2 = CyclomaticComplexityConfiguration(length: length2)
        #expect(configuration2.length == length2)
    }

    @Test
    func cyclomaticComplexityConfigurationInitializerSetsIgnoresCaseStatements() {
        let configuration1 = CyclomaticComplexityConfiguration(
            length: SeverityLevelsConfiguration(warning: 10, error: 30),
            ignoresCaseStatements: true
        )
        #expect(configuration1.ignoresCaseStatements)

        let configuration2 = CyclomaticComplexityConfiguration(
            length: SeverityLevelsConfiguration(warning: 10, error: 30)
        )
        #expect(!configuration2.ignoresCaseStatements)
    }

    @Test
    func cyclomaticComplexityConfigurationApplyConfigurationWithDictionary() throws {
        var configuration = CyclomaticComplexityConfiguration(
            length: SeverityLevelsConfiguration(warning: 0, error: 0)
        )

        let warning1 = 10
        let error1 = 30
        let length1 = SeverityLevelsConfiguration<CyclomaticComplexityRule>(warning: warning1, error: error1)
        let config1: [String: Any] = [
            "warning": warning1,
            "error": error1,
            "ignores_case_statements": true,
        ]

        let warning2 = 20
        let error2 = 40
        let length2 = SeverityLevelsConfiguration<CyclomaticComplexityRule>(warning: warning2, error: error2)
        let config2: [String: Int] = ["warning": warning2, "error": error2]
        let config3: [String: Bool] = ["ignores_case_statements": false]

        try configuration.apply(configuration: config1)
        #expect(configuration.length == length1)
        #expect(configuration.ignoresCaseStatements)

        try configuration.apply(configuration: config2)
        #expect(configuration.length == length2)
        #expect(configuration.ignoresCaseStatements)

        try configuration.apply(configuration: config3)
        #expect(configuration.length == length2)
        #expect(!configuration.ignoresCaseStatements)
    }

    @Test
    func cyclomaticComplexityConfigurationThrowsOnBadConfigValues() {
        let badConfigs: [[String: Any]] = [
            ["warning": true],
            ["ignores_case_statements": 300],
        ]

        for badConfig in badConfigs {
            var configuration = CyclomaticComplexityConfiguration(
                length: SeverityLevelsConfiguration<CyclomaticComplexityRule>(warning: 100, error: 150)
            )
            checkError(Issue.invalidConfiguration(ruleID: CyclomaticComplexityRule.identifier)) {
                try configuration.apply(configuration: badConfig)
            }
        }
    }

    @Test
    func cyclomaticComplexityConfigurationCompares() {
        let config1 = CyclomaticComplexityConfiguration(
            length: SeverityLevelsConfiguration(warning: 10, error: 30)
        )
        let config2 = CyclomaticComplexityConfiguration(
            length: SeverityLevelsConfiguration(warning: 10, error: 30),
            ignoresCaseStatements: true
        )
        let config3 = CyclomaticComplexityConfiguration(
            length: SeverityLevelsConfiguration(warning: 10, error: 30),
            ignoresCaseStatements: false
        )
        let config4 = CyclomaticComplexityConfiguration(
            length: SeverityLevelsConfiguration(warning: 10, error: 40)
        )
        let config5 = CyclomaticComplexityConfiguration(
            length: SeverityLevelsConfiguration(warning: 20, error: 30)
        )
        #expect(config1 != config2)
        #expect(config1 == config3)
        #expect(config1 != config4)
        #expect(config1 != config5)
    }
}
