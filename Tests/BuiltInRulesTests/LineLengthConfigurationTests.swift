import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct LineLengthConfigurationTests {
    private let severityLevels = SeverityLevelsConfiguration<LineLengthRule>(warning: 100, error: 150)

    @Test
    func lineLengthConfigurationInitializerSetsLength() {
        let configuration1 = LineLengthConfiguration(length: severityLevels)
        #expect(configuration1.length == severityLevels)

        let length2 = SeverityLevelsConfiguration<LineLengthRule>(warning: 100, error: nil)
        let configuration2 = LineLengthConfiguration(length: length2)
        #expect(configuration2.length == length2)
    }

    @Test
    func lineLengthConfigurationInitialiserSetsIgnoresURLs() {
        let configuration1 = LineLengthConfiguration(length: severityLevels, ignoresURLs: true)

        #expect(configuration1.ignoresURLs)

        let configuration2 = LineLengthConfiguration(length: severityLevels)
        #expect(!configuration2.ignoresURLs)
    }

    @Test
    func lineLengthConfigurationInitialiserSetsIgnoresFunctionDeclarations() {
        let configuration1 = LineLengthConfiguration(length: severityLevels, ignoresFunctionDeclarations: true)
        #expect(configuration1.ignoresFunctionDeclarations)

        let configuration2 = LineLengthConfiguration(length: severityLevels)
        #expect(!configuration2.ignoresFunctionDeclarations)
    }

    @Test
    func lineLengthConfigurationInitialiserSetsIgnoresComments() {
        let configuration1 = LineLengthConfiguration(length: severityLevels, ignoresComments: true)
        #expect(configuration1.ignoresComments)

        let configuration2 = LineLengthConfiguration(length: severityLevels)
        #expect(!configuration2.ignoresComments)
    }

    @Test
    func lineLengthConfigurationInitialiserSetsIgnoresInterpolatedStrings() {
        let configuration1 = LineLengthConfiguration(length: severityLevels, ignoresInterpolatedStrings: true)
        #expect(configuration1.ignoresInterpolatedStrings)

        let configuration2 = LineLengthConfiguration(length: severityLevels)
        #expect(!configuration2.ignoresInterpolatedStrings)
    }

    @Test
    func lineLengthConfigurationInitialiserSetsIgnoresMultilineStrings() {
        let configuration1 = LineLengthConfiguration(length: severityLevels, ignoresMultilineStrings: true)
        #expect(configuration1.ignoresMultilineStrings)

        let configuration2 = LineLengthConfiguration(length: severityLevels)
        #expect(!configuration2.ignoresMultilineStrings)
    }

    @Test
    func lineLengthConfigurationInitialiserSetsExcludedLinesPatterns() {
        let patterns: Set = ["foo", "bar"]
        let configuration1 = LineLengthConfiguration(length: severityLevels, excludedLinesPatterns: patterns)
        #expect(configuration1.excludedLinesPatterns == patterns)

        let configuration2 = LineLengthConfiguration(length: severityLevels)
        #expect(configuration2.excludedLinesPatterns.isEmpty)
    }

    @Test
    func lineLengthConfigurationParams() {
        let warning = 13
        let error = 10
        let configuration = LineLengthConfiguration(length: SeverityLevelsConfiguration(warning: warning, error: error))
        let params = [RuleParameter(severity: .error, value: error), RuleParameter(severity: .warning, value: warning)]
        #expect(configuration.params == params)
    }

    @Test
    func lineLengthConfigurationPartialParams() {
        let configuration = LineLengthConfiguration(length: SeverityLevelsConfiguration(warning: 13))
        #expect(configuration.params == [RuleParameter(severity: .warning, value: 13)])
    }

    @Test
    func lineLengthConfigurationThrowsOnBadConfig() {
        let config = ["warning": "unknown"]
        var configuration = LineLengthConfiguration(length: severityLevels)
        checkError(Issue.invalidConfiguration(ruleID: LineLengthRule.identifier)) {
            try configuration.apply(configuration: config)
        }
    }

    @Test
    func lineLengthConfigurationThrowsOnBadConfigValues() {
        let badConfigs: [[String: Any]] = [
            ["warning": true],
            ["ignores_function_declarations": 300],
        ]

        for badConfig in badConfigs {
            var configuration = LineLengthConfiguration(length: severityLevels)
            checkError(Issue.invalidConfiguration(ruleID: LineLengthRule.identifier)) {
                try configuration.apply(configuration: badConfig)
            }
        }
    }

    @Test
    func lineLengthConfigurationApplyConfigurationWithArray() throws {
        var configuration = LineLengthConfiguration(length: SeverityLevelsConfiguration(warning: 0, error: 0))

        let warning1 = 100
        let error1 = 100
        let length1 = SeverityLevelsConfiguration<LineLengthRule>(warning: warning1, error: error1)
        let config1 = [warning1, error1]

        let warning2 = 150
        let length2 = SeverityLevelsConfiguration<LineLengthRule>(warning: warning2, error: nil)
        let config2 = [warning2]

        try configuration.apply(configuration: config1)
        #expect(configuration.length == length1)

        try configuration.apply(configuration: config2)
        #expect(configuration.length == length2)
    }

    @Test
    func lineLengthConfigurationApplyConfigurationWithDictionary() throws {
        var configuration = LineLengthConfiguration(length: SeverityLevelsConfiguration(warning: 0, error: 0))

        let warning1 = 100
        let error1 = 100
        let length1 = SeverityLevelsConfiguration<LineLengthRule>(warning: warning1, error: error1)
        let config1: [String: Any] = [
            "warning": warning1,
            "error": error1,
            "ignores_urls": true,
            "ignores_function_declarations": true,
            "ignores_comments": true,
        ]

        let warning2 = 200
        let error2 = 200
        let length2 = SeverityLevelsConfiguration<LineLengthRule>(warning: warning2, error: error2)
        let config2: [String: Int] = ["warning": warning2, "error": error2]

        let config3: [String: Bool] = [
            "ignores_urls": false,
            "ignores_function_declarations": false,
            "ignores_comments": false,
        ]

        try configuration.apply(configuration: config1)
        #expect(configuration.length == length1)
        #expect(configuration.ignoresURLs)
        #expect(configuration.ignoresFunctionDeclarations)
        #expect(configuration.ignoresComments)

        try configuration.apply(configuration: config2)
        #expect(configuration.length == length2)
        #expect(configuration.ignoresURLs)
        #expect(configuration.ignoresFunctionDeclarations)
        #expect(configuration.ignoresComments)

        try configuration.apply(configuration: config3)
        #expect(configuration.length == length2)
        #expect(!configuration.ignoresURLs)
        #expect(!configuration.ignoresFunctionDeclarations)
        #expect(!configuration.ignoresComments)
    }

    @Test
    func lineLengthConfigurationCompares() {
        let configuration1 = LineLengthConfiguration(length: SeverityLevelsConfiguration(warning: 100, error: 100))
        let configuration2 = LineLengthConfiguration(
            length: SeverityLevelsConfiguration(warning: 100, error: 100),
            ignoresFunctionDeclarations: true,
            ignoresComments: true
        )
        #expect(configuration1 != configuration2)

        let configuration3 = LineLengthConfiguration(length: SeverityLevelsConfiguration(warning: 100, error: 200))
        #expect(configuration1 != configuration3)

        let configuration4 = LineLengthConfiguration(length: SeverityLevelsConfiguration(warning: 200, error: 200))
        #expect(configuration1 != configuration4)

        let configuration5 = LineLengthConfiguration(length: SeverityLevelsConfiguration(warning: 100, error: 100))
        #expect(configuration1 == configuration5)

        let configuration6 = LineLengthConfiguration(
            length: SeverityLevelsConfiguration(warning: 100, error: 100),
            ignoresFunctionDeclarations: true,
            ignoresComments: true
        )
        #expect(configuration2 == configuration6)
    }
}
