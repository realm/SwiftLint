import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct ValidIBInspectableConfigurationTests {
    @Test
    func severityAndAdditionalTypes() throws {
        var configuration = ValidIBInspectableConfiguration()
        #expect(configuration.additionalTypes.isEmpty)
        try configuration.apply(configuration: [
            "severity": "error",
            "additional_types": ["Angle", "Module.Angle", "Angle"],
        ])
        #expect(configuration.severity == .error)
        #expect(configuration.additionalTypes == ["Angle", "Module.Angle"])
    }

    @Test
    func rejectsInvalidAdditionalTypes() {
        for value: Any in [42, false] {
            var configuration = ValidIBInspectableConfiguration()
            #expect(throws: Issue.invalidConfiguration(ruleID: ValidIBInspectableRule.identifier)) {
                try configuration.apply(configuration: ["additional_types": value])
            }
        }
    }

    @Test
    func preservesSeverityShorthand() {
        verifyRule(ValidIBInspectableRule.description, ruleConfiguration: "error")
    }
}
