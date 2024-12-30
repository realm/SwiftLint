@testable import SwiftLintBuiltInRules
import TestHelpers
import XCTest

final class ChildOptionSeverityConfigurationTests: SwiftLintTestCase {
    typealias TesteeType = ChildOptionSeverityConfiguration<RuleMock>

    func testSeverity() {
        XCTAssertNil(TesteeType.off.severity)
        XCTAssertEqual(TesteeType.warning.severity, .warning)
        XCTAssertEqual(TesteeType.error.severity, .error)
    }

    func testFromConfig() throws {
        var testee = TesteeType.off

        try testee.apply(configuration: "warning")
        XCTAssertEqual(testee, .warning)

        try testee.apply(configuration: "error")
        XCTAssertEqual(testee, .error)

        try testee.apply(configuration: "off")
        XCTAssertEqual(testee, .off)
    }

    func testInvalidConfig() {
        var testee = TesteeType.off

        XCTAssertThrowsError(try testee.apply(configuration: "no"))
        XCTAssertThrowsError(try testee.apply(configuration: 1))
    }
}
