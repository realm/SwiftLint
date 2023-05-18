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
        XCTAssertEqual(configuration.severityConfiguration.severity, .error)
        XCTAssertEqual(configuration.includedKinds, expectedKinds)
    }

    func testImplicitReturnConfigurationThrowsOnUnrecognizedModifierGroup() {
        var configuration = ImplicitReturnConfiguration()
        let config = ["included": ["foreach"]] as [String: Any]

        checkError(Issue.unknownConfiguration(ruleID: ImplicitReturnRule.description.identifier)) {
            try configuration.apply(configuration: config)
        }
    }
}
