@testable import SwiftLintBuiltInRules
import TestHelpers
import XCTest

final class OneDeclarationPerFileConfigurationTest: SwiftLintTestCase {
    func testOneDeclarationPerFileConfigurationCheckSettingIgnoredTypes() throws {
        let initial: [OneDeclarationPerFileConfiguration.IgnoredType] = [
            .actor, .class
        ]
        let configuration = OneDeclarationPerFileConfiguration(severityConfiguration: .warning, ignoredTypes: initial)
        XCTAssertEqual(Set(initial), configuration.allowedTypes)
    }

    func testOneDeclarationPerFileConfigurationGoodConfig() throws {
        let ignoredTypes = OneDeclarationPerFileConfiguration.IgnoredType.all
        let ignoredTypesString: [String] = ignoredTypes.map(\.rawValue)
            .sorted()
        let goodConfig: [String: Any] = [
            "severity": "error",
            "ignored_types": ignoredTypesString,
        ]
        var configuration = OneDeclarationPerFileConfiguration()
        try configuration.apply(configuration: goodConfig)
        XCTAssertEqual(configuration.severityConfiguration.severity, .error)
        XCTAssertEqual(configuration.allowedTypes, ignoredTypes)
    }

    func testOneDeclarationPerFileConfigurationBadConfigWrongTypes() throws {
        let badConfig: [String: Any] = [
            "severity": "error",
            "ignored_types": ["clas"],
        ]
        var configuration = OneDeclarationPerFileConfiguration()
        checkError(Issue.invalidConfiguration(ruleID: OneDeclarationPerFileRule.identifier)) {
            try configuration.apply(configuration: badConfig)
        }
    }
}
