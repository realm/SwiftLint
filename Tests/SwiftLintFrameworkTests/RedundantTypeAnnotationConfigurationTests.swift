@testable import SwiftLintBuiltInRules
import XCTest

// swiftlint:disable:next type_name
class RedundantTypeAnnotationConfigurationTests: XCTestCase {
    func testInit() {
        let config = RedundantTypeAnnotationConfiguration()
        XCTAssertEqual(config.severityConfiguration, SeverityConfiguration(.warning))
        XCTAssertFalse(config.ignoreBooleans)
    }

    func testApplyThrows() throws {
        var config = RedundantTypeAnnotationConfiguration()
        let nonStringAnyDict = ""
        XCTAssertThrowsError(try config.apply(configuration: nonStringAnyDict)) { error in
            XCTAssertEqual(error as? Issue, Issue.unknownConfiguration(ruleID: "redundant_type_annotation"))
        }
    }

    func testApply() throws {
        var config = RedundantTypeAnnotationConfiguration()
        XCTAssertNoThrow(try config.apply(configuration: ["severity": "error", "ignore_booleans": true]))
        XCTAssertEqual(config.severityConfiguration, SeverityConfiguration(.error))
        XCTAssertTrue(config.ignoreBooleans)
    }
}
