@testable import SwiftLintFramework
import XCTest

class TrailingClosureConfigurationTests: SwiftLintTestCase {
    func testDefaultConfiguration() {
        let config = TrailingClosureConfiguration()
        XCTAssertEqual(config.severityConfiguration.severity, .warning)
        XCTAssertFalse(config.onlySingleMutedParameter)
    }

    func testApplyingCustomConfiguration() throws {
        var config = TrailingClosureConfiguration()
        try config.apply(configuration: ["severity": "error",
                                         "only_single_muted_parameter": true])
        XCTAssertEqual(config.severityConfiguration.severity, .error)
        XCTAssertTrue(config.onlySingleMutedParameter)
    }
}
