import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct UnusedDeclarationConfigurationTests {
    @Test
    func parseConfiguration() throws {
        var testee = UnusedDeclarationConfiguration()
        let config = [
            "severity": "warning",
            "include_public_and_open": true,
            "related_usrs_to_skip": ["a", "b"],
        ] as [String: any Sendable]

        try testee.apply(configuration: config)

        #expect(testee.severityConfiguration.severity == .warning)
        #expect(testee.includePublicAndOpen)
        #expect(testee.relatedUSRsToSkip == ["a", "b", "s:7SwiftUI15PreviewProviderP"])
    }
}
