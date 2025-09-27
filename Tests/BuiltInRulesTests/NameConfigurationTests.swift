import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct NameConfigurationTests {
    typealias TesteeType = NameConfiguration<RuleMock>

    @Test
    func nameConfigurationSetsCorrectly() {
        let config: [String: any Sendable] = [
            "min_length": ["warning": 17, "error": 7],
            "max_length": ["warning": 170, "error": 700],
            "excluded": "id",
            "allowed_symbols": ["$"],
            "validates_start_with_lowercase": "warning",
        ]
        var nameConfig = TesteeType(minLengthWarning: 0,
                                    minLengthError: 0,
                                    maxLengthWarning: 0,
                                    maxLengthError: 0)
        let comp = TesteeType(minLengthWarning: 17,
                              minLengthError: 7,
                              maxLengthWarning: 170,
                              maxLengthError: 700,
                              excluded: ["id"],
                              allowedSymbols: ["$"],
                              validatesStartWithLowercase: .warning)
        do {
            try nameConfig.apply(configuration: config)
            #expect(nameConfig == comp)
        } catch {
            Testing.Issue.record("Did not configure correctly")
        }
    }

    @Test
    func caseCheck() throws {
        var nameConfig = TesteeType(
            minLengthWarning: 0,
            minLengthError: 0,
            maxLengthWarning: 0,
            maxLengthError: 0
        )

        #expect(nameConfig.validatesStartWithLowercase == .error)

        try nameConfig.apply(configuration: ["validates_start_with_lowercase": "off"])
        #expect(nameConfig.validatesStartWithLowercase == .off)

        try nameConfig.apply(configuration: ["validates_start_with_lowercase": "warning"])
        #expect(nameConfig.validatesStartWithLowercase == .warning)
    }

    @Test
    func nameConfigurationThrowsOnBadConfig() {
        let config = 17
        var nameConfig = TesteeType(
            minLengthWarning: 0,
            minLengthError: 0,
            maxLengthWarning: 0,
            maxLengthError: 0
        )
        #expect(throws: Issue.invalidConfiguration(ruleID: RuleMock.identifier)) {
            try nameConfig.apply(configuration: config)
        }
    }

    @Test
    func nameConfigurationMinLengthThreshold() {
        let nameConfig = TesteeType(
            minLengthWarning: 7,
            minLengthError: 17,
            maxLengthWarning: 0,
            maxLengthError: 0,
            excluded: []
        )
        #expect(nameConfig.minLengthThreshold == 17)
    }

    @Test
    func nameConfigurationMaxLengthThreshold() {
        let nameConfig = TesteeType(
            minLengthWarning: 0,
            minLengthError: 0,
            maxLengthWarning: 17,
            maxLengthError: 7,
            excluded: []
        )
        #expect(nameConfig.maxLengthThreshold == 7)
    }

    @Test
    func unallowedSymbolsSeverity() throws {
        var nameConfig = TesteeType(
            minLengthWarning: 3,
            minLengthError: 1,
            maxLengthWarning: 17,
            maxLengthError: 22,
            unallowedSymbolsSeverity: .warning
        )

        #expect(nameConfig.unallowedSymbolsSeverity == .warning)
        try nameConfig.apply(configuration: ["unallowed_symbols_severity": "error"])
        #expect(nameConfig.unallowedSymbolsSeverity == .error)
    }
}
