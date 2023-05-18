@testable import SwiftLintBuiltInRules
import XCTest

class NameConfigurationTests: SwiftLintTestCase {
    func testNameConfigurationSetsCorrectly() {
        let config = [ "min_length": ["warning": 17, "error": 7],
                       "max_length": ["warning": 170, "error": 700],
                       "excluded": "id",
                       "allowed_symbols": ["$"],
                       "validates_start_with_lowercase": "warning"] as [String: Any]
        var nameConfig = NameConfiguration(minLengthWarning: 0,
                                           minLengthError: 0,
                                           maxLengthWarning: 0,
                                           maxLengthError: 0)
        let comp = NameConfiguration(minLengthWarning: 17,
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
        var nameConfig = NameConfiguration(minLengthWarning: 0,
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
        var nameConfig = NameConfiguration(minLengthWarning: 0,
                                           minLengthError: 0,
                                           maxLengthWarning: 0,
                                           maxLengthError: 0)
        checkError(Issue.unknownConfiguration) {
            try nameConfig.apply(configuration: config)
        }
    }

    func testNameConfigurationMinLengthThreshold() {
        let nameConfig = NameConfiguration(minLengthWarning: 7,
                                           minLengthError: 17,
                                           maxLengthWarning: 0,
                                           maxLengthError: 0,
                                           excluded: [])
        XCTAssertEqual(nameConfig.minLengthThreshold, 17)
    }

    func testNameConfigurationMaxLengthThreshold() {
        let nameConfig = NameConfiguration(minLengthWarning: 0,
                                           minLengthError: 0,
                                           maxLengthWarning: 17,
                                           maxLengthError: 7,
                                           excluded: [])
        XCTAssertEqual(nameConfig.maxLengthThreshold, 7)
    }
}
