@testable import SwiftLintBuiltInRules
import TestHelpers
import XCTest

final class NameConfigurationTests: SwiftLintTestCase {
    typealias TesteeType = NameConfiguration<RuleMock>

    func testNameConfigurationSetsCorrectly() {
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
            XCTAssertEqual(nameConfig, comp)
        } catch {
            XCTFail("Did not configure correctly")
        }
    }

    func testCaseCheck() throws {
        var nameConfig = TesteeType(minLengthWarning: 0,
                                    minLengthError: 0,
                                    maxLengthWarning: 0,
                                    maxLengthError: 0)

        XCTAssertEqual(nameConfig.validatesStartWithLowercase, .error)

        try nameConfig.apply(configuration: ["validates_start_with_lowercase": "off"])
        XCTAssertEqual(nameConfig.validatesStartWithLowercase, .off)

        try nameConfig.apply(configuration: ["validates_start_with_lowercase": "warning"])
        XCTAssertEqual(nameConfig.validatesStartWithLowercase, .warning)
    }

    func testNameConfigurationWithDeprecatedBooleanSeverity() throws {
        var nameConfig = TesteeType(minLengthWarning: 0,
                                    minLengthError: 0,
                                    maxLengthWarning: 0,
                                    maxLengthError: 0)

        XCTAssertEqual(nameConfig.validatesStartWithLowercase, .error)

        try nameConfig.apply(configuration: ["validates_start_with_lowercase": false])
        XCTAssertEqual(nameConfig.validatesStartWithLowercase, .off)

        try nameConfig.apply(configuration: ["validates_start_with_lowercase": true])
        XCTAssertEqual(nameConfig.validatesStartWithLowercase, .error)
    }

    func testNameConfigurationThrowsOnBadConfig() {
        let config = 17
        var nameConfig = TesteeType(minLengthWarning: 0,
                                    minLengthError: 0,
                                    maxLengthWarning: 0,
                                    maxLengthError: 0)
        checkError(Issue.invalidConfiguration(ruleID: RuleMock.identifier)) {
            try nameConfig.apply(configuration: config)
        }
    }

    func testNameConfigurationMinLengthThreshold() {
        let nameConfig = TesteeType(minLengthWarning: 7,
                                    minLengthError: 17,
                                    maxLengthWarning: 0,
                                    maxLengthError: 0,
                                    excluded: [])
        XCTAssertEqual(nameConfig.minLengthThreshold, 17)
    }

    func testNameConfigurationMaxLengthThreshold() {
        let nameConfig = TesteeType(minLengthWarning: 0,
                                    minLengthError: 0,
                                    maxLengthWarning: 17,
                                    maxLengthError: 7,
                                    excluded: [])
        XCTAssertEqual(nameConfig.maxLengthThreshold, 7)
    }

    func testUnallowedSymbolsSeverity() throws {
        var nameConfig = TesteeType(minLengthWarning: 3,
                                    minLengthError: 1,
                                    maxLengthWarning: 17,
                                    maxLengthError: 22,
                                    unallowedSymbolsSeverity: .warning)
        XCTAssertEqual(nameConfig.unallowedSymbolsSeverity, .warning)

        try nameConfig.apply(configuration: ["unallowed_symbols_severity": "error"])

        XCTAssertEqual(nameConfig.unallowedSymbolsSeverity, .error)
    }
}
