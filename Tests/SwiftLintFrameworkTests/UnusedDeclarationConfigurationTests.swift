@testable import SwiftLintBuiltInRules
import XCTest

class UnusedDeclarationConfigurationTests: XCTestCase {
    func testParseConfiguration() throws {
        var testee = UnusedDeclarationConfiguration(
            severityConfiguration: .warning,
            includePublicAndOpen: false,
            relatedUSRsToSkip: []
        )
        let config = [
            "severity": "error",
            "include_public_and_open": true,
            "related_usrs_to_skip": ["a", "b"]
        ] as [String: Any]

        try testee.apply(configuration: config)

        XCTAssertEqual(testee.severityConfiguration.severity, .error)
        XCTAssertTrue(testee.includePublicAndOpen)
        XCTAssertEqual(testee.relatedUSRsToSkip, ["a", "b"])
    }
}
