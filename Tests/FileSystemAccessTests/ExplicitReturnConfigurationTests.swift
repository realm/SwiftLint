@testable import SwiftLintBuiltInRules
import TestHelpers
import XCTest

final class ExplicitReturnConfigurationTests: SwiftLintTestCase {
    func testExplicitReturnConfigurationFromDictionary() throws {
        var configuration = ExplicitReturnConfiguration(includedKinds: Set<ExplicitReturnConfiguration.ReturnKind>())
        let config: [String: Any] = [
            "severity": "error",
            "included": [
                "closure",
                "function",
                "getter",
                "initializer",
                "subscript",
            ],
        ]

        try configuration.apply(configuration: config)
        let expectedKinds: Set<ExplicitReturnConfiguration.ReturnKind> = Set([
            .closure,
            .function,
            .getter,
            .initializer,
            .subscript,
        ])
        XCTAssertEqual(configuration.severityConfiguration.severity, .error)
        XCTAssertEqual(configuration.includedKinds, expectedKinds)
    }

    func testExplicitReturnConfigurationThrowsOnUnrecognizedModifierGroup() {
        var configuration = ExplicitReturnConfiguration()
        let config = ["included": ["foreach"]] as [String: any Sendable]

        checkError(Issue.invalidConfiguration(ruleID: ExplicitReturnRule.identifier)) {
            try configuration.apply(configuration: config)
        }
    }
}
