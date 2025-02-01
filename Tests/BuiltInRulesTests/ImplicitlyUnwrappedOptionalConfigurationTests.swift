import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct ImplicitlyUnwrappedOptionalConfigurationTests { // swiftlint:disable:this type_name

    @Test
    func implicitlyUnwrappedOptionalConfigurationProperlyAppliesConfigurationFromDictionary() throws {
        var configuration = ImplicitlyUnwrappedOptionalConfiguration(
            severityConfiguration: SeverityConfiguration(.warning),
            mode: .allExceptIBOutlets
        )

        try configuration.apply(configuration: ["mode": "all", "severity": "error"])
        #expect(configuration.mode == .all)
        #expect(configuration.severity == .error)

        try configuration.apply(configuration: ["mode": "all_except_iboutlets"])
        #expect(configuration.mode == .allExceptIBOutlets)
        #expect(configuration.severity == .error)

        try configuration.apply(configuration: ["severity": "warning"])
        #expect(configuration.mode == .allExceptIBOutlets)
        #expect(configuration.severity == .warning)

        try configuration.apply(configuration: ["mode": "all", "severity": "warning"])
        #expect(configuration.mode == .all)
        #expect(configuration.severity == .warning)
    }

    @Test
    func implicitlyUnwrappedOptionalConfigurationThrowsOnBadConfig() {
        let badConfigs: [[String: Any]] = [
            ["mode": "everything"],
            ["mode": false],
            ["mode": 42],
        ]

        for badConfig in badConfigs {
            var configuration = ImplicitlyUnwrappedOptionalConfiguration(
                severityConfiguration: SeverityConfiguration(.warning),
                mode: .allExceptIBOutlets
            )

            #expect(throws: Issue.invalidConfiguration(ruleID: ImplicitlyUnwrappedOptionalRule.identifier)) {
                try configuration.apply(configuration: badConfig)
            }
        }
    }
}
