@testable import SwiftLintFramework
import XCTest

class ExplicitReturnConfigurationTests: XCTestCase {
    func testExplicitReturnConfigurationFromDictionary() throws {
        var configuration = ExplicitReturnConfiguration(includedKinds: Set<ExplicitReturnConfiguration.ReturnKind>())
        let config: [String: Any] = [
            "severity": "error",
            "included": [
                "closure",
                "function",
                "getter"
            ]
        ]

        try configuration.apply(configuration: config)
        let expectedKinds: Set<ExplicitReturnConfiguration.ReturnKind> = Set([
            .closure,
            .function,
            .getter
        ])
        XCTAssert(configuration.severityConfiguration.severity == .error)
        XCTAssertTrue(configuration.includedKinds == expectedKinds)
    }

    func testExplicitReturnConfigurationThrowsOnUnrecognizedModifierGroup() {
        var configuration = ExplicitReturnConfiguration()
        let config = ["included": ["foreach"]] as [String: Any]

        checkError(ConfigurationError.unknownConfiguration) {
            try configuration.apply(configuration: config)
        }
    }
}
