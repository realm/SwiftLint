import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct TypeBodyLengthConfigurationTests {
    @Test
    func defaultConfiguration() {
        let config = TypeBodyLengthConfiguration()
        #expect(config.severityConfiguration.warning == 250)
        #expect(config.severityConfiguration.error == 350)
        #expect(config.excludedTypes == [.extension, .protocol])
    }

    @Test
    func applyingCustomConfiguration() throws {
        var config = TypeBodyLengthConfiguration()
        try config.apply(
            configuration: [
                "warning": 150,
                "error": 200,
                "excluded_types": ["struct", "class"],
            ] as [String: any Sendable]
        )
        #expect(config.severityConfiguration.warning == 150)
        #expect(config.severityConfiguration.error == 200)
        #expect(config.excludedTypes == Set([.struct, .class]))
    }

    @Test
    func applyingOnlyExcludedTypesConfiguration() throws {
        var config = TypeBodyLengthConfiguration()
        try config.apply(
            configuration: [
                "excluded_types": ["actor", "enum"]
            ] as [String: any Sendable]
        )

        // Severity should remain default
        #expect(config.severityConfiguration.warning == 250)
        #expect(config.severityConfiguration.error == 350)

        // Excluded types should be updated
        #expect(config.excludedTypes == Set([.actor, .enum]))
    }

    @Test
    func applyingAllTypesAsExcludedConfiguration() throws {
        var config = TypeBodyLengthConfiguration()
        try config.apply(
            configuration: [
                "excluded_types": ["struct", "class", "actor", "enum", "extension", "protocol"]
            ] as [String: any Sendable]
        )
        #expect(config.excludedTypes == Set(TypeBodyLengthCheckType.allCases))
    }

    @Test
    func applyingEmptyExcludedTypesConfiguration() throws {
        var config = TypeBodyLengthConfiguration()
        try config.apply(
            configuration: [
                "excluded_types": [] as [String]
            ] as [String: any Sendable]
        )
        #expect(config.excludedTypes.isEmpty)
    }

    @Test
    func applyingSingleExcludedTypeConfiguration() throws {
        var config = TypeBodyLengthConfiguration()
        try config.apply(
            configuration: [
                "excluded_types": ["extension"]
            ] as [String: any Sendable]
        )
        #expect(config.excludedTypes == Set([.extension]))
    }

    @Test
    func invalidExcludedTypeConfiguration() throws {
        var config = TypeBodyLengthConfiguration()
        checkError(Issue.invalidConfiguration(ruleID: TypeBodyLengthRule.identifier)) {
            try config.apply(
                configuration: [
                    "excluded_types": ["invalid_type"]
                ] as [String: any Sendable]
            )
        }
        #expect(config.excludedTypes == Set([.extension, .protocol]))
    }

    @Test
    func typeEnumComparability() {
        #expect(
            TypeBodyLengthCheckType.allCases.sorted() == [.actor, .class, .enum, .extension, .protocol, .struct]
        )
    }
}
