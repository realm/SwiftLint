@testable import SwiftLintBuiltInRules
import XCTest

class NameConfigurationTests: SwiftLintTestCase {
    typealias TesteeType = NameConfiguration<RuleMock>

    func testNameConfigurationSetsCorrectly() {
        let config = [ "min_length": ["warning": 17, "error": 7],
                       "max_length": ["warning": 170, "error": 700],
                       "excluded": "id",
                       "allowed_symbols": ["$"],
                       "validates_start_with_lowercase": "warning"] as [String: Any]
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

    func testNameConfigurationWithDeprecatedBooleanSeverity() throws {
        var nameConfig = TesteeType(minLengthWarning: 0,
                                    minLengthError: 0,
                                    maxLengthWarning: 0,
                                    maxLengthError: 0)

        XCTAssertEqual(nameConfig.validatesStartWithLowercase, .error)

        try nameConfig.apply(configuration: ["validates_start_with_lowercase": false])
        XCTAssertNil(nameConfig.validatesStartWithLowercase)

        try nameConfig.apply(configuration: ["validates_start_with_lowercase": true])
        XCTAssertEqual(nameConfig.validatesStartWithLowercase, .error)
    }

    func testNameConfigurationThrowsOnBadConfig() {
        let config = 17
        var nameConfig = TesteeType(minLengthWarning: 0,
                                    minLengthError: 0,
                                    maxLengthWarning: 0,
                                    maxLengthError: 0)
        checkError(Issue.unknownConfiguration(ruleID: RuleMock.description.identifier)) {
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
}
