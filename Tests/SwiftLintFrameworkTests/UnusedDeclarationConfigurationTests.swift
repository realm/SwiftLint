@testable import SwiftLintBuiltInRules
import XCTest

final class UnusedDeclarationConfigurationTests: XCTestCase {
    func testParseConfiguration() throws {
        var testee = UnusedDeclarationConfiguration()
        let config = [
            "severity": "warning",
            "include_public_and_open": true,
            "related_usrs_to_skip": ["a", "b"],
        ] as [String: any Sendable]

        try testee.apply(configuration: config)

        XCTAssertEqual(testee.severityConfiguration.severity, .warning)
        XCTAssertTrue(testee.includePublicAndOpen)
        XCTAssertEqual(testee.relatedUSRsToSkip, ["a", "b", "s:7SwiftUI15PreviewProviderP"])
    }
}
