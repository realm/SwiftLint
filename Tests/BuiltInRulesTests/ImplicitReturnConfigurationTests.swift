@testable import SwiftLintBuiltInRules
import TestHelpers
import Testing

@Suite(.rulesRegistered)
struct ImplicitReturnConfigurationTests {
    @Test
    func implicitReturnConfigurationFromDictionary() throws {
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
        #expect(configuration.severityConfiguration.severity == .error)
        #expect(configuration.includedKinds == expectedKinds)
    }

    @Test
    func implicitReturnConfigurationThrowsOnUnrecognizedModifierGroup() {
        var configuration = ImplicitReturnConfiguration()
        let config = ["included": ["foreach"]] as [String: any Sendable]

        checkError(Issue.invalidConfiguration(ruleID: ImplicitReturnRule.identifier)) {
            try configuration.apply(configuration: config)
        }
    }
}
