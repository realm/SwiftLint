import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct TrailingClosureConfigurationTests {
    @Test
    func defaultConfiguration() {
        let config = TrailingClosureConfiguration()
        #expect(config.severityConfiguration.severity == .warning)
        #expect(!config.onlySingleMutedParameter)
    }

    @Test
    func applyingCustomConfiguration() throws {
        var config = TrailingClosureConfiguration()
        try config.apply(
            configuration: [
                "severity": "error",
                "only_single_muted_parameter": true,
            ] as [String: any Sendable]
        )
        #expect(config.severityConfiguration.severity == .error)
        #expect(config.onlySingleMutedParameter)
    }
}
