@testable import SwiftLintBuiltInRules
import TestHelpers
import XCTest

final class MissingDocsRuleTests: SwiftLintTestCase {
    func testDescriptionEmpty() {
        let configuration = MissingDocsConfiguration()
        XCTAssertEqual(
            configuration.parameterDescription?.oneLiner(),
            "warning: [open, public]; excludes_extensions: true; " +
            "excludes_inherited_types: true; excludes_trivial_init: false; " +
            "evaluate_effective_access_control_level: false"
        )
    }

    func testDescriptionExcludesFalse() {
        let configuration = MissingDocsConfiguration(excludesExtensions: false, excludesInheritedTypes: false)
        XCTAssertEqual(
            configuration.parameterDescription?.oneLiner(),
            "warning: [open, public]; excludes_extensions: false; " +
            "excludes_inherited_types: false; excludes_trivial_init: false; " +
            "evaluate_effective_access_control_level: false"
        )
    }

    func testDescriptionExcludesExtensionsFalseExcludesInheritedTypesTrue() {
        let configuration = MissingDocsConfiguration(excludesExtensions: false, excludesInheritedTypes: true)
        XCTAssertEqual(
            configuration.parameterDescription?.oneLiner(),
            "warning: [open, public]; excludes_extensions: false; " +
            "excludes_inherited_types: true; excludes_trivial_init: false; " +
            "evaluate_effective_access_control_level: false"
        )
    }

    func testDescriptionExcludesExtensionsTrueExcludesInheritedTypesFalse() {
        let configuration = MissingDocsConfiguration(
            excludesExtensions: true,
            excludesInheritedTypes: false,
            evaluateEffectiveAccessControlLevel: true
        )
        XCTAssertEqual(
            configuration.parameterDescription?.oneLiner(),
            "warning: [open, public]; excludes_extensions: true; " +
            "excludes_inherited_types: false; excludes_trivial_init: false; " +
            "evaluate_effective_access_control_level: true"
        )
    }

    func testDescriptionSingleServety() {
        let configuration = MissingDocsConfiguration(
            parameters: [RuleParameter<AccessControlLevel>(severity: .error, value: .open)])
        XCTAssertEqual(
            configuration.parameterDescription?.oneLiner(),
            "error: [open]; excludes_extensions: true; " +
            "excludes_inherited_types: true; excludes_trivial_init: false; " +
            "evaluate_effective_access_control_level: false"
        )
    }

    func testDescriptionMultipleSeverities() {
        let configuration = MissingDocsConfiguration(
            parameters: [
                RuleParameter<AccessControlLevel>(severity: .error, value: .open),
                RuleParameter<AccessControlLevel>(severity: .warning, value: .public),
            ]
        )
        XCTAssertEqual(
            configuration.parameterDescription?.oneLiner(),
            "error: [open]; warning: [public]; excludes_extensions: true; " +
            "excludes_inherited_types: true; excludes_trivial_init: false; " +
            "evaluate_effective_access_control_level: false"
        )
    }

    func testDescriptionMultipleAcls() {
        let configuration = MissingDocsConfiguration(
            parameters: [
                RuleParameter<AccessControlLevel>(severity: .warning, value: .open),
                RuleParameter<AccessControlLevel>(severity: .warning, value: .public),
            ]
        )
        XCTAssertEqual(
            configuration.parameterDescription?.oneLiner(),
            "warning: [open, public]; excludes_extensions: true; " +
            "excludes_inherited_types: true; excludes_trivial_init: false; " +
            "evaluate_effective_access_control_level: false"
        )
    }

    func testDescriptionExcludesTrivialInitTrue() {
        let configuration = MissingDocsConfiguration(excludesTrivialInit: true)
        XCTAssertEqual(
            configuration.parameterDescription?.oneLiner(),
            "warning: [open, public]; excludes_extensions: true; " +
            "excludes_inherited_types: true; excludes_trivial_init: true; " +
            "evaluate_effective_access_control_level: false"
        )
    }

    func testParsingSingleServety() {
        var configuration = MissingDocsConfiguration()
        try? configuration.apply(configuration: ["warning": "open"])
        XCTAssertEqual(
            configuration.parameters,
            [RuleParameter<AccessControlLevel>(severity: .warning, value: .open)]
        )
    }

    func testParsingMultipleSeverities() {
        var configuration = MissingDocsConfiguration()
        try? configuration.apply(configuration: ["warning": "public", "error": "open"])
        XCTAssertEqual(
            configuration.parameters.sorted { $0.value.rawValue > $1.value.rawValue },
            [
                RuleParameter<AccessControlLevel>(severity: .warning, value: .public),
                RuleParameter<AccessControlLevel>(severity: .error, value: .open),
            ]
        )
    }

    func testParsingMultipleAcls() {
        var configuration = MissingDocsConfiguration()
        try? configuration.apply(configuration: ["warning": ["public", "open"]])
        XCTAssertEqual(
            configuration.parameters.sorted { $0.value.rawValue > $1.value.rawValue },
            [
                RuleParameter<AccessControlLevel>(severity: .warning, value: .public),
                RuleParameter<AccessControlLevel>(severity: .warning, value: .open),
            ]
        )
        XCTAssertTrue(configuration.excludesExtensions)
        XCTAssertTrue(configuration.excludesInheritedTypes)
    }

    func testInvalidServety() {
        var configuration = MissingDocsConfiguration()
        XCTAssertThrowsError(try configuration.apply(configuration: ["warning": ["public", "closed"]]))
    }

    func testInvalidAcl() {
        var configuration = MissingDocsConfiguration()
        try? configuration.apply(configuration: ["debug": ["public", "open"]])
        XCTAssertTrue(configuration.excludesExtensions)
        XCTAssertTrue(configuration.excludesInheritedTypes)
        XCTAssertEqual(
            configuration.parameters.sorted { $0.value.rawValue > $1.value.rawValue },
            [
                RuleParameter<AccessControlLevel>(severity: .warning, value: .public),
                RuleParameter<AccessControlLevel>(severity: .warning, value: .open),
            ]
        )
    }

    func testInvalidDuplicateAcl() {
        var configuration = MissingDocsConfiguration()
        XCTAssertThrowsError(
            try configuration.apply(configuration: ["warning": ["public", "open"] as Any, "error": "public"])
        )
    }

    func testExcludesFalse() {
        var configuration = MissingDocsConfiguration()
        try? configuration.apply(configuration: ["excludes_extensions": false, "excludes_inherited_types": false])
        XCTAssertFalse(configuration.excludesExtensions)
        XCTAssertFalse(configuration.excludesInheritedTypes)
        XCTAssertEqual(
            configuration.parameters.sorted { $0.value.rawValue > $1.value.rawValue },
            [
                RuleParameter<AccessControlLevel>(severity: .warning, value: .public),
                RuleParameter<AccessControlLevel>(severity: .warning, value: .open),
            ]
        )
    }

    func testExcludesExtensionsFalseExcludesInheritedTypesTrue() {
        var configuration = MissingDocsConfiguration()
        try? configuration.apply(configuration: ["excludes_extensions": false, "excludes_inherited_types": true])
        XCTAssertFalse(configuration.excludesExtensions)
        XCTAssertTrue(configuration.excludesInheritedTypes)
        XCTAssertEqual(
            configuration.parameters.sorted { $0.value.rawValue > $1.value.rawValue },
            [
                RuleParameter<AccessControlLevel>(severity: .warning, value: .public),
                RuleParameter<AccessControlLevel>(severity: .warning, value: .open),
            ]
        )
    }

    func testExcludesExtensionsTrueExcludesInheritedTypesFalse() {
        var configuration = MissingDocsConfiguration()
        try? configuration.apply(configuration: ["excludes_extensions": true, "excludes_inherited_types": false])
        XCTAssertTrue(configuration.excludesExtensions)
        XCTAssertFalse(configuration.excludesInheritedTypes)
        XCTAssertEqual(
            configuration.parameters.sorted { $0.value.rawValue > $1.value.rawValue },
            [
                RuleParameter<AccessControlLevel>(severity: .warning, value: .public),
                RuleParameter<AccessControlLevel>(severity: .warning, value: .open),
            ]
        )
    }

    func testExcludesExtensionsTrueExcludesInheritedTypesFalseWithParameters() {
        var configuration = MissingDocsConfiguration()
        try? configuration.apply(
            configuration: [
                "excludes_extensions": true,
                "excludes_inherited_types": false,
                "error": ["public"],
            ] as [String: any Sendable]
        )

        XCTAssertTrue(configuration.excludesExtensions)
        XCTAssertFalse(configuration.excludesInheritedTypes)
        XCTAssertEqual(
            configuration.parameters.sorted { $0.value.rawValue > $1.value.rawValue },
            [RuleParameter<AccessControlLevel>(severity: .error, value: .public)]
        )
    }
}
