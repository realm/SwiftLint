@testable import SwiftLintFramework
import XCTest

class UnusedDeclarationConfigurationTests: XCTestCase {
    func testParseConfiguration() throws {
        var testee = UnusedDeclarationConfiguration(
            severity: .warning,
            includePublicAndOpen: false,
            relatedUSRsToSkip: []
        )
        let config: Any = [
            "severity": "error",
            "include_public_and_open": true,
            "related_usrs_to_skip": ["a", "b"]
        ]

        try testee.apply(configuration: config)

        XCTAssertEqual(testee.severityConfiguration.severity, .error)
        XCTAssertTrue(testee.includePublicAndOpen)
        XCTAssertEqual(testee.relatedUSRsToSkip, ["a", "b"])
    }
}
