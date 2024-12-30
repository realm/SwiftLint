@testable import SwiftLintBuiltInRules
import TestHelpers
import XCTest

final class ImplicitReturnConfigurationTests: SwiftLintTestCase {
    func testImplicitReturnConfigurationFromDictionary() throws {
        var configuration = ImplicitReturnConfiguration(includedKinds: Set<ImplicitReturnConfiguration.ReturnKind>())
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
        let expectedKinds: Set<ImplicitReturnConfiguration.ReturnKind> = Set([
            .closure,
            .function,
            .getter,
            .initializer,
            .subscript,
        ])
        XCTAssertEqual(configuration.severityConfiguration.severity, .error)
        XCTAssertEqual(configuration.includedKinds, expectedKinds)
    }

    func testImplicitReturnConfigurationThrowsOnUnrecognizedModifierGroup() {
        var configuration = ImplicitReturnConfiguration()
        let config = ["included": ["foreach"]] as [String: any Sendable]

        checkError(Issue.invalidConfiguration(ruleID: ImplicitReturnRule.identifier)) {
            try configuration.apply(configuration: config)
        }
    }
}
