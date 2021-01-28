@testable import SwiftLintFramework
import XCTest

class MissingDocsRuleConfigurationTests: XCTestCase {
    func testDescriptionEmpty() {
        let configuration = MissingDocsRuleConfiguration()
        XCTAssertEqual(configuration.consoleDescription, "mind_incomplete_docs: true")
    }

    func testDescriptionSingleSeverity() {
        let configuration = MissingDocsRuleConfiguration(
            parameters: [RuleParameter<AccessControlLevel>(severity: .error, value: .open)])
        XCTAssertEqual(configuration.consoleDescription, "error: open, mind_incomplete_docs: true")
    }

    func testDescriptionSingleSeverityWithoutMindIncompleteDocs() {
        let configuration = MissingDocsRuleConfiguration(
            parameters: [RuleParameter<AccessControlLevel>(severity: .error, value: .open)],
            mindIncompleteDocs: false)
        XCTAssertEqual(configuration.consoleDescription, "error: open, mind_incomplete_docs: false")
    }

    func testDescriptionMultipleSeverities() {
        let configuration = MissingDocsRuleConfiguration(
            parameters: [RuleParameter<AccessControlLevel>(severity: .error, value: .open),
                         RuleParameter<AccessControlLevel>(severity: .warning, value: .public)])
        XCTAssertEqual(configuration.consoleDescription, "error: open, warning: public, mind_incomplete_docs: true")
    }

    func testDescriptionMultipleSeveritiesWithoutMindIncompleteDocs() {
        let configuration = MissingDocsRuleConfiguration(
            parameters: [RuleParameter<AccessControlLevel>(severity: .error, value: .open),
                         RuleParameter<AccessControlLevel>(severity: .warning, value: .public)],
            mindIncompleteDocs: false)
        XCTAssertEqual(configuration.consoleDescription, "error: open, warning: public, mind_incomplete_docs: false")
    }

    func testDescriptionMultipleAcls() {
        let configuration = MissingDocsRuleConfiguration(
            parameters: [RuleParameter<AccessControlLevel>(severity: .warning, value: .open),
                         RuleParameter<AccessControlLevel>(severity: .warning, value: .public)])
        XCTAssertEqual(configuration.consoleDescription, "warning: open, public, mind_incomplete_docs: true")
    }

    func testDescriptionMultipleAclsWithoutMindIncompleteDocs() {
        let configuration = MissingDocsRuleConfiguration(
            parameters: [RuleParameter<AccessControlLevel>(severity: .warning, value: .open),
                         RuleParameter<AccessControlLevel>(severity: .warning, value: .public)],
            mindIncompleteDocs: false)
        XCTAssertEqual(configuration.consoleDescription, "warning: open, public, mind_incomplete_docs: false")
    }

    func testParsingSingleSeverity() {
        var configuration = MissingDocsRuleConfiguration()
        try? configuration.apply(configuration: ["warning": "open"])
        XCTAssertEqual(configuration.parameters, [RuleParameter<AccessControlLevel>(severity: .warning, value: .open)])
        XCTAssertTrue(configuration.mindIncompleteDocs)
    }

    func testParsingSingleSeverityWithoutMindIncompleteDocs() {
        var configuration = MissingDocsRuleConfiguration()
        try? configuration.apply(configuration: ["warning": "open", "mind_incomplete_docs": false])
        XCTAssertEqual(configuration.parameters, [RuleParameter<AccessControlLevel>(severity: .warning, value: .open)])
        XCTAssertFalse(configuration.mindIncompleteDocs)
    }

    func testParsingMultipleSeverities() {
        var configuration = MissingDocsRuleConfiguration()
        try? configuration.apply(configuration: ["warning": "public", "error": "open"])
        XCTAssertEqual(configuration.parameters.sorted { $0.value.rawValue > $1.value.rawValue },
                       [RuleParameter<AccessControlLevel>(severity: .warning, value: .public),
                        RuleParameter<AccessControlLevel>(severity: .error, value: .open)])
        XCTAssertTrue(configuration.mindIncompleteDocs)
    }

    func testParsingMultipleSeveritiesWithoutMindIncompleteDocs() {
        var configuration = MissingDocsRuleConfiguration()
        try? configuration.apply(configuration: ["warning": "public", "error": "open", "mind_incomplete_docs": false])
        XCTAssertEqual(configuration.parameters.sorted { $0.value.rawValue > $1.value.rawValue },
                       [RuleParameter<AccessControlLevel>(severity: .warning, value: .public),
                        RuleParameter<AccessControlLevel>(severity: .error, value: .open)])
        XCTAssertFalse(configuration.mindIncompleteDocs)
    }

    func testParsingMultipleAcls() {
        var configuration = MissingDocsRuleConfiguration()
        try? configuration.apply(configuration: ["warning": ["public", "open"]])
        XCTAssertEqual(configuration.parameters.sorted { $0.value.rawValue > $1.value.rawValue },
                       [RuleParameter<AccessControlLevel>(severity: .warning, value: .public),
                        RuleParameter<AccessControlLevel>(severity: .warning, value: .open)])
        XCTAssertTrue(configuration.mindIncompleteDocs)
    }

    func testParsingMultipleAclsWithoutMindIncompleteDocs() {
        var configuration = MissingDocsRuleConfiguration()
        try? configuration.apply(configuration: ["warning": ["public", "open"], "mind_incomplete_docs": false])
        XCTAssertEqual(configuration.parameters.sorted { $0.value.rawValue > $1.value.rawValue },
                       [RuleParameter<AccessControlLevel>(severity: .warning, value: .public),
                        RuleParameter<AccessControlLevel>(severity: .warning, value: .open)])
        XCTAssertFalse(configuration.mindIncompleteDocs)
    }

    func testInvalidSeverity() {
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
