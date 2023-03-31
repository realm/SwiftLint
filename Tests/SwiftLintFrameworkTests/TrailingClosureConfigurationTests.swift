@testable import SwiftLintFramework
import XCTest

class TrailingClosureConfigurationTests: XCTestCase {
    func testDefaultConfiguration() {
        let config = TrailingClosureConfiguration()
        XCTAssertEqual(config.severityConfiguration.severity, .warning)
        XCTAssertFalse(config.onlySingleMutedParameter)
    }

    func testApplyingCustomConfiguration() throws {
        var config = TrailingClosureConfiguration()
        try config.apply(configuration: ["severity": "error",
                                         "only_single_muted_parameter": true] as [String: Any])
        XCTAssertEqual(config.severityConfiguration.severity, .error)
        XCTAssertTrue(config.onlySingleMutedParameter)
    }
}
