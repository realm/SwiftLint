@testable import SwiftLintFramework
import XCTest

class MissingDocsRuleTests: SwiftLintTestCase {
    func testDescriptionEmpty() {
        let configuration = MissingDocsRuleConfiguration()
        XCTAssertEqual(
            configuration.consoleDescription,
            "warning: open, public, excludes_extensions: true, " +
            "excludes_inherited_types: true, excludes_trivial_init: false"
        )
    }

    func testDescriptionExcludesFalse() {
        let configuration = MissingDocsRuleConfiguration(excludesExtensions: false, excludesInheritedTypes: false)
        XCTAssertEqual(
            configuration.consoleDescription,
            "warning: open, public, excludes_extensions: false, " +
            "excludes_inherited_types: false, excludes_trivial_init: false"
        )
    }

    func testDescriptionExcludesExtensionsFalseExcludesInheritedTypesTrue() {
        let configuration = MissingDocsRuleConfiguration(excludesExtensions: false, excludesInheritedTypes: true)
        XCTAssertEqual(
            configuration.consoleDescription,
            "warning: open, public, excludes_extensions: false, " +
            "excludes_inherited_types: true, excludes_trivial_init: false"
        )
    }

    func testDescriptionExcludesExtensionsTrueExcludesInheritedTypesFalse() {
        let configuration = MissingDocsRuleConfiguration(excludesExtensions: true, excludesInheritedTypes: false)
        XCTAssertEqual(
            configuration.consoleDescription,
            "warning: open, public, excludes_extensions: true, " +
            "excludes_inherited_types: false, excludes_trivial_init: false"
        )
    }

    func testDescriptionSingleServety() {
        let configuration = MissingDocsRuleConfiguration(
            parameters: [RuleParameter<AccessControlLevel>(severity: .error, value: .open)])
        XCTAssertEqual(
            configuration.consoleDescription,
            "error: open, excludes_extensions: true, " +
            "excludes_inherited_types: true, excludes_trivial_init: false"
        )
    }

    func testDescriptionMultipleSeverities() {
        let configuration = MissingDocsRuleConfiguration(
            parameters: [RuleParameter<AccessControlLevel>(severity: .error, value: .open),
                         RuleParameter<AccessControlLevel>(severity: .warning, value: .public)])
        XCTAssertEqual(
            configuration.consoleDescription,
            "error: open, warning: public, excludes_extensions: true, " +
            "excludes_inherited_types: true, excludes_trivial_init: false"
        )
    }

    func testDescriptionMultipleAcls() {
        let configuration = MissingDocsRuleConfiguration(
            parameters: [RuleParameter<AccessControlLevel>(severity: .warning, value: .open),
                         RuleParameter<AccessControlLevel>(severity: .warning, value: .public)])
        XCTAssertEqual(
            configuration.consoleDescription,
            "warning: open, public, excludes_extensions: true, " +
            "excludes_inherited_types: true, excludes_trivial_init: false"
        )
    }

    func testDescriptionExcludesTrivialInitTrue() {
        let configuration = MissingDocsRuleConfiguration(excludesTrivialInit: true)
        XCTAssertEqual(
            configuration.consoleDescription,
            "warning: open, public, excludes_extensions: true, " +
            "excludes_inherited_types: true, excludes_trivial_init: true"
        )
    }

    func testParsingSingleServety() {
        var configuration = MissingDocsRuleConfiguration()
        try? configuration.apply(configuration: ["warning": "open"])
        XCTAssertEqual(
            configuration.parameters,
            [RuleParameter<AccessControlLevel>(severity: .warning, value: .open)]
        )
    }

    func testParsingMultipleSeverities() {
        var configuration = MissingDocsRuleConfiguration()
        try? configuration.apply(configuration: ["warning": "public", "error": "open"])
        XCTAssertEqual(
            configuration.parameters.sorted { $0.value.rawValue > $1.value.rawValue },
            [RuleParameter<AccessControlLevel>(severity: .warning, value: .public),
             RuleParameter<AccessControlLevel>(severity: .error, value: .open)]
        )
    }

    func testParsingMultipleAcls() {
        var configuration = MissingDocsRuleConfiguration()
        try? configuration.apply(configuration: ["warning": ["public", "open"]])
        XCTAssertEqual(
            configuration.parameters.sorted { $0.value.rawValue > $1.value.rawValue },
            [RuleParameter<AccessControlLevel>(severity: .warning, value: .public),
             RuleParameter<AccessControlLevel>(severity: .warning, value: .open)]
        )
        XCTAssertTrue(configuration.excludesExtensions)
        XCTAssertTrue(configuration.excludesInheritedTypes)
    }

    func testInvalidServety() {
        var configuration = MissingDocsRuleConfiguration()
        XCTAssertThrowsError(try configuration.apply(configuration: ["warning": ["public", "closed"]]))
    }

    func testInvalidAcl() {
        var configuration = MissingDocsRuleConfiguration()
        try? configuration.apply(configuration: ["debug": ["public", "open"]])
        XCTAssertTrue(configuration.excludesExtensions)
        XCTAssertTrue(configuration.excludesInheritedTypes)
        XCTAssertEqual(
            configuration.parameters.sorted { $0.value.rawValue > $1.value.rawValue },
            [RuleParameter<AccessControlLevel>(severity: .warning, value: .public),
             RuleParameter<AccessControlLevel>(severity: .warning, value: .open)]
        )
    }

    func testInvalidDuplicateAcl() {
        var configuration = MissingDocsRuleConfiguration()
        XCTAssertThrowsError(try configuration.apply(configuration: ["warning": ["public", "open"], "error": "public"]))
    }

    func testExcludesFalse() {
        var configuration = MissingDocsRuleConfiguration()
        try? configuration.apply(configuration: ["excludes_extensions": false, "excludes_inherited_types": false])
        XCTAssertFalse(configuration.excludesExtensions)
        XCTAssertFalse(configuration.excludesInheritedTypes)
        XCTAssertEqual(
            configuration.parameters.sorted { $0.value.rawValue > $1.value.rawValue },
            [RuleParameter<AccessControlLevel>(severity: .warning, value: .public),
             RuleParameter<AccessControlLevel>(severity: .warning, value: .open)]
        )
    }

    func testExcludesExtensionsFalseExcludesInheritedTypesTrue() {
        var configuration = MissingDocsRuleConfiguration()
        try? configuration.apply(configuration: ["excludes_extensions": false, "excludes_inherited_types": true])
        XCTAssertFalse(configuration.excludesExtensions)
        XCTAssertTrue(configuration.excludesInheritedTypes)
        XCTAssertEqual(
            configuration.parameters.sorted { $0.value.rawValue > $1.value.rawValue },
            [RuleParameter<AccessControlLevel>(severity: .warning, value: .public),
             RuleParameter<AccessControlLevel>(severity: .warning, value: .open)]
        )
    }

    func testExcludesExtensionsTrueExcludesInheritedTypesFalse() {
        var configuration = MissingDocsRuleConfiguration()
        try? configuration.apply(configuration: ["excludes_extensions": true, "excludes_inherited_types": false])
        XCTAssertTrue(configuration.excludesExtensions)
        XCTAssertFalse(configuration.excludesInheritedTypes)
        XCTAssertEqual(
            configuration.parameters.sorted { $0.value.rawValue > $1.value.rawValue },
            [RuleParameter<AccessControlLevel>(severity: .warning, value: .public),
             RuleParameter<AccessControlLevel>(severity: .warning, value: .open)]
        )
    }

    func testExcludesExtensionsTrueExcludesInheritedTypesFalseWithParameters() {
        var configuration = MissingDocsRuleConfiguration()
        try? configuration.apply(
            configuration: [
                "excludes_extensions": true,
                "excludes_inherited_types": false,
                "error": ["public"]
            ]
        )

        XCTAssertTrue(configuration.excludesExtensions)
        XCTAssertFalse(configuration.excludesInheritedTypes)
        XCTAssertEqual(
            configuration.parameters.sorted { $0.value.rawValue > $1.value.rawValue },
            [RuleParameter<AccessControlLevel>(severity: .error, value: .public)]
        )
    }

    func testWithExcludesExtensionsDisabled() {
        // Perform additional tests with the ignores_comments settings disabled.
        let baseDescription = MissingDocsRule.description
        let triggeringComments = [
            Example("""
            public extension A {}
            """
            )
        ]
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples
            .filter { !triggeringComments.contains($0) }
        let triggeringExamples = baseDescription.triggeringExamples + triggeringComments
        let description = baseDescription
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)
        verifyRule(description,
                   ruleConfiguration: ["excludes_extensions": false])
    }

    func testWithExcludesInheritedTypesDisabled() {
        // Perform additional tests with the ignores_comments settings disabled.
        let baseDescription = MissingDocsRule.description
        let triggeringComments = [
            // locally-defined superclass member is documented, but subclass member is not
            Example("""
            /// docs
            public class A {
            /// docs
            public func b() {}
            }
            // no docs
            public class B: A { override public func b() {} }
            """),
            // externally-defined superclass member is documented, but subclass member is not
            Example("""
            import Foundation
            // no docs
            public class B: NSObject {
            // no docs
            override public var description: String { fatalError() } }
            """)
        ]
        let nonTriggeringExamples = baseDescription.nonTriggeringExamples
            .filter { !triggeringComments.contains($0) }
        let triggeringExamples = baseDescription.triggeringExamples + triggeringComments
        let description = baseDescription
            .with(nonTriggeringExamples: nonTriggeringExamples)
            .with(triggeringExamples: triggeringExamples)
        verifyRule(description,
                   ruleConfiguration: ["excludes_inherited_types": false])
    }
}
