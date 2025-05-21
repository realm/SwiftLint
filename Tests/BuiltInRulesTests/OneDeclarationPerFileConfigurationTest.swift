@testable import SwiftLintBuiltInRules
import TestHelpers
import XCTest

final class OneDeclarationPerFileConfigurationTest: SwiftLintTestCase {
    func testOneDeclarationPerFileConfigurationCheckSettingAllowedTypes() throws {
        let initial: [OneDeclarationPerFileConfiguration.AllowedType] = [
            .actor, .class
        ]
        let config = OneDeclarationPerFileConfiguration(severityConfiguration: .warning, allowedTypes: initial)
        XCTAssertEqual(Set(initial), config.enabledTypes)
    }

    func testOneDeclarationPerFileConfigurationGoodConfig() throws {
        let allowedTypes = OneDeclarationPerFileConfiguration.AllowedType.all
        let allowedTypesString: [String] = allowedTypes.map(\.rawValue)
            .sorted()
        let goodConfig: [String: Any] = [
            "severity": "error",
            "allowed_types": allowedTypesString,
        ]
        var configuration = OneDeclarationPerFileConfiguration()
        try configuration.apply(configuration: goodConfig)
        XCTAssertEqual(configuration.severityConfiguration.severity, .error)
        XCTAssertEqual(configuration.enabledTypes, allowedTypes)
    }

    func testOneDeclarationPerFileConfigurationBadConfigWrongTypes() throws {
        let badConfig: [String: Any] = [
            "severity": "error",
            "allowed_types": ["clas"],
        ]
        var configuration = OneDeclarationPerFileConfiguration()
        checkError(Issue.invalidConfiguration(ruleID: OneDeclarationPerFileRule.identifier)) {
            try configuration.apply(configuration: badConfig)
        }
    }
}
