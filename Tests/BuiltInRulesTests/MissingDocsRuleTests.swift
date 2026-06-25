import TestHelpers
import Testing

@testable import SwiftLintBuiltInRules

@Suite(.rulesRegistered)
struct MissingDocsRuleTests {
    @Test
    func descriptionEmpty() {
        let configuration = MissingDocsConfiguration()
        #expect(
            configuration.parameterDescription?.oneLiner() == """
                warning: [open, public]; excludes_extensions: true; \
                excludes_inherited_types: true; excludes_trivial_init: false; \
                evaluate_effective_access_control_level: false
                """
        )
    }

    @Test
    func descriptionExcludesFalse() {
        let configuration = MissingDocsConfiguration(excludesExtensions: false, excludesInheritedTypes: false)
        #expect(
            configuration.parameterDescription?.oneLiner() == """
                warning: [open, public]; excludes_extensions: false; \
                excludes_inherited_types: false; excludes_trivial_init: false; \
                evaluate_effective_access_control_level: false
                """
        )
    }

    @Test
    func descriptionExcludesExtensionsFalseExcludesInheritedTypesTrue() {
        let configuration = MissingDocsConfiguration(excludesExtensions: false, excludesInheritedTypes: true)
        #expect(
            configuration.parameterDescription?.oneLiner() == """
                warning: [open, public]; excludes_extensions: false; \
                excludes_inherited_types: true; excludes_trivial_init: false; \
                evaluate_effective_access_control_level: false
                """
        )
    }

    @Test
    func descriptionExcludesExtensionsTrueExcludesInheritedTypesFalse() {
        let configuration = MissingDocsConfiguration(
            excludesExtensions: true,
            excludesInheritedTypes: false,
            evaluateEffectiveAccessControlLevel: true
        )
        #expect(
            configuration.parameterDescription?.oneLiner() == """
                warning: [open, public]; excludes_extensions: true; \
                excludes_inherited_types: false; excludes_trivial_init: false; \
                evaluate_effective_access_control_level: true
                """
        )
    }

    @Test
    func descriptionSingleServety() {
        let configuration = MissingDocsConfiguration(
            parameters: [RuleParameter<AccessControlLevel>(severity: .error, value: .open)])
        #expect(
            configuration.parameterDescription?.oneLiner() == """
                error: [open]; excludes_extensions: true; \
                excludes_inherited_types: true; excludes_trivial_init: false; \
                evaluate_effective_access_control_level: false
                """
        )
    }

    @Test
    func descriptionMultipleSeverities() {
        let configuration = MissingDocsConfiguration(
            parameters: [
                RuleParameter<AccessControlLevel>(severity: .error, value: .open),
                RuleParameter<AccessControlLevel>(severity: .warning, value: .public),
            ]
        )
        #expect(
            configuration.parameterDescription?.oneLiner() == """
                error: [open]; warning: [public]; excludes_extensions: true; \
                excludes_inherited_types: true; excludes_trivial_init: false; \
                evaluate_effective_access_control_level: false
                """
        )
    }

    @Test
    func descriptionMultipleAcls() {
        let configuration = MissingDocsConfiguration(
            parameters: [
                RuleParameter<AccessControlLevel>(severity: .warning, value: .open),
                RuleParameter<AccessControlLevel>(severity: .warning, value: .public),
            ]
        )
        #expect(
            configuration.parameterDescription?.oneLiner() == """
                warning: [open, public]; excludes_extensions: true; \
                excludes_inherited_types: true; excludes_trivial_init: false; \
                evaluate_effective_access_control_level: false
                """
        )
    }

    @Test
    func descriptionExcludesTrivialInitTrue() {
        let configuration = MissingDocsConfiguration(excludesTrivialInit: true)
        #expect(
            configuration.parameterDescription?.oneLiner() == """
                warning: [open, public]; excludes_extensions: true; \
                excludes_inherited_types: true; excludes_trivial_init: true; \
                evaluate_effective_access_control_level: false
                """
        )
    }

    @Test
    func parsingSingleServety() {
        var configuration = MissingDocsConfiguration()
        try? configuration.apply(configuration: ["warning": "open"])
        #expect(
            configuration.parameters == [RuleParameter<AccessControlLevel>(severity: .warning, value: .open)]
        )
    }

    @Test
    func parsingMultipleSeverities() {
        var configuration = MissingDocsConfiguration()
        try? configuration.apply(configuration: ["warning": "public", "error": "open"])
        #expect(
            configuration.parameters.sorted { $0.value.rawValue > $1.value.rawValue } == [
                RuleParameter<AccessControlLevel>(severity: .warning, value: .public),
                RuleParameter<AccessControlLevel>(severity: .error, value: .open),
            ]
        )
    }

    @Test
    func parsingMultipleAcls() {
        var configuration = MissingDocsConfiguration()
        try? configuration.apply(configuration: ["warning": ["public", "open"]])
        #expect(
            configuration.parameters.sorted { $0.value.rawValue > $1.value.rawValue } == [
                RuleParameter<AccessControlLevel>(severity: .warning, value: .public),
                RuleParameter<AccessControlLevel>(severity: .warning, value: .open),
            ]
        )
        #expect(configuration.excludesExtensions)
        #expect(configuration.excludesInheritedTypes)
    }

    @Test
    func invalidServety() {
        var configuration = MissingDocsConfiguration()
        #expect(throws: (any Error).self) {
            try configuration.apply(configuration: ["warning": ["public", "closed"]])
        }
    }

    @Test
    func invalidAcl() {
        var configuration = MissingDocsConfiguration()
        try? configuration.apply(configuration: ["debug": ["public", "open"]])
        #expect(configuration.excludesExtensions)
        #expect(configuration.excludesInheritedTypes)
        #expect(
            configuration.parameters.sorted { $0.value.rawValue > $1.value.rawValue } == [
                RuleParameter<AccessControlLevel>(severity: .warning, value: .public),
                RuleParameter<AccessControlLevel>(severity: .warning, value: .open),
            ]
        )
    }

    @Test
    func invalidDuplicateAcl() {
        var configuration = MissingDocsConfiguration()
        #expect(throws: (any Error).self) {
            try configuration.apply(configuration: ["warning": ["public", "open"] as Any, "error": "public"])
        }
    }

    @Test
    func excludesFalse() {
        var configuration = MissingDocsConfiguration()
        try? configuration.apply(configuration: ["excludes_extensions": false, "excludes_inherited_types": false])
        #expect(!configuration.excludesExtensions)
        #expect(!configuration.excludesInheritedTypes)
        #expect(
            configuration.parameters.sorted { $0.value.rawValue > $1.value.rawValue } == [
                RuleParameter<AccessControlLevel>(severity: .warning, value: .public),
                RuleParameter<AccessControlLevel>(severity: .warning, value: .open),
            ]
        )
    }

    @Test
    func excludesExtensionsFalseExcludesInheritedTypesTrue() {
        var configuration = MissingDocsConfiguration()
        try? configuration.apply(configuration: ["excludes_extensions": false, "excludes_inherited_types": true])
        #expect(!configuration.excludesExtensions)
        #expect(configuration.excludesInheritedTypes)
        #expect(
            configuration.parameters.sorted { $0.value.rawValue > $1.value.rawValue } == [
                RuleParameter<AccessControlLevel>(severity: .warning, value: .public),
                RuleParameter<AccessControlLevel>(severity: .warning, value: .open),
            ]
        )
    }

    @Test
    func excludesExtensionsTrueExcludesInheritedTypesFalse() {
        var configuration = MissingDocsConfiguration()
        try? configuration.apply(configuration: ["excludes_extensions": true, "excludes_inherited_types": false])
        #expect(configuration.excludesExtensions)
        #expect(!configuration.excludesInheritedTypes)
        #expect(
            configuration.parameters.sorted { $0.value.rawValue > $1.value.rawValue } == [
                RuleParameter<AccessControlLevel>(severity: .warning, value: .public),
                RuleParameter<AccessControlLevel>(severity: .warning, value: .open),
            ]
        )
    }

    @Test
    func excludesExtensionsTrueExcludesInheritedTypesFalseWithParameters() {
        var configuration = MissingDocsConfiguration()
        try? configuration.apply(
            configuration: [
                "excludes_extensions": true,
                "excludes_inherited_types": false,
                "error": ["public"],
            ] as [String: any Sendable]
        )

        #expect(configuration.excludesExtensions)
        #expect(!configuration.excludesInheritedTypes)
        #expect(
            configuration.parameters.sorted { $0.value.rawValue > $1.value.rawValue }
                == [RuleParameter<AccessControlLevel>(severity: .error, value: .public)]
        )
    }
}
