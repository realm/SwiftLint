@testable import SwiftLintBuiltInRules
import XCTest

class ImplicitReturnConfigurationTests: SwiftLintTestCase {
    func testImplicitReturnConfigurationFromDictionary() throws {
        var configuration = ImplicitReturnConfiguration(includedKinds: Set<ImplicitReturnConfiguration.ReturnKind>())
        let config: [String: Any] = [
            "severity": "error",
            "included": [
                "closure",
                "function",
                "getter"
            ]
        ]

        try configuration.apply(configuration: config)
        let expectedKinds: Set<ImplicitReturnConfiguration.ReturnKind> = Set([
            .closure,
            .function,
            .getter
        ])
        XCTAssert(configuration.severityConfiguration.severity == .error)
        XCTAssertTrue(configuration.includedKinds == expectedKinds)
    }

    func testImplicitReturnConfigurationThrowsOnUnrecognizedModifierGroup() {
        var configuration = ImplicitReturnConfiguration()
        let config = ["included": ["foreach"]] as [String: Any]

        checkError(ConfigurationError.unknownConfiguration) {
            try configuration.apply(configuration: config)
        }
    }
}
