@testable import SwiftLintFramework
import XCTest

class MissingDocsRuleConfigurationTests: XCTestCase {
    func testDescriptionEmpty() {
        let configuration = MissingDocsRuleConfiguration()
        XCTAssertEqual(
            configuration.consoleDescription,
            "excludes_extensions: true, excludes_inherited_types: true"
        )
    }

    func testDescriptionExcludesFalse() {
        let configuration = MissingDocsRuleConfiguration(excludesExtensions: false, excludesInheritedTypes: false)
        XCTAssertEqual(
            configuration.consoleDescription,
            "excludes_extensions: false, excludes_inherited_types: false"
        )
    }

    func testDescriptionSingleServety() {
        let configuration = MissingDocsRuleConfiguration(
            parameters: [RuleParameter<AccessControlLevel>(severity: .error, value: .open)])
        XCTAssertEqual(
            configuration.consoleDescription,
            "error: open, excludes_extensions: true, excludes_inherited_types: true"
        )
    }

    func testDescriptionMultipleSeverities() {
        let configuration = MissingDocsRuleConfiguration(
            parameters: [RuleParameter<AccessControlLevel>(severity: .error, value: .open),
                         RuleParameter<AccessControlLevel>(severity: .warning, value: .public)])
        XCTAssertEqual(
            configuration.consoleDescription,
            "error: open, warning: public, excludes_extensions: true, excludes_inherited_types: true"
        )
    }

    func testDescriptionMultipleAcls() {
        let configuration = MissingDocsRuleConfiguration(
            parameters: [RuleParameter<AccessControlLevel>(severity: .warning, value: .open),
                         RuleParameter<AccessControlLevel>(severity: .warning, value: .public)])
        XCTAssertEqual(
            configuration.consoleDescription,
            "warning: open, public, excludes_extensions: true, excludes_inherited_types: true"
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
    }

    func testInvalidServety() {
        var configuration = MissingDocsRuleConfiguration()
        XCTAssertThrowsError(try configuration.apply(configuration: ["warning": ["public", "closed"]]))
    }

    func testInvalidAcl() {
        var configuration = MissingDocsRuleConfiguration()
        XCTAssertThrowsError(try configuration.apply(configuration: ["debug": ["public", "open"]]))
    }

    func testInvalidDuplicateAcl() {
        var configuration = MissingDocsRuleConfiguration()
        XCTAssertThrowsError(try configuration.apply(configuration: ["warning": ["public", "open"], "error": "public"]))
    }
}
