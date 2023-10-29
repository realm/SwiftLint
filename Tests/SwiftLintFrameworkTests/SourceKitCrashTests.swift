@_spi(TestHelper)
@testable import SwiftLintCore
import XCTest

class SourceKitCrashTests: SwiftLintTestCase {
    func testAssertHandlerIsNotCalledOnNormalFile() {
        let file = SwiftLintFile(contents: "A file didn't crash SourceKitService")
        file.sourcekitdFailed = false

        var assertHandlerCalled = false
        file.assertHandler = { assertHandlerCalled = true }

        _ = file.sourceKitSyntaxMap
        XCTAssertFalse(assertHandlerCalled,
                       "Expects assert handler was not called on accessing SwiftLintFile.syntaxMap")

        assertHandlerCalled = false
        _ = file.sourceKitSyntaxKindsByLines
        XCTAssertFalse(assertHandlerCalled,
                       "Expects assert handler was not called on accessing SwiftLintFile.syntaxKindsByLines")

        assertHandlerCalled = false
        _ = file.sourceKitSyntaxTokensByLines
        XCTAssertFalse(assertHandlerCalled,
                       "Expects assert handler was not called on accessing SwiftLintFile.syntaxTokensByLines")
    }

    func testAssertHandlerIsCalledOnFileThatCrashedSourceKitService() {
        let file = SwiftLintFile(contents: "A file crashed SourceKitService")
        file.sourcekitdFailed = true

        var assertHandlerCalled = false
        file.assertHandler = { assertHandlerCalled = true }

        _ = file.sourceKitSyntaxMap
        XCTAssertTrue(assertHandlerCalled,
                      "Expects assert handler was called on accessing SwiftLintFile.syntaxMap")

        assertHandlerCalled = false
        _ = file.sourceKitSyntaxKindsByLines
        XCTAssertTrue(assertHandlerCalled,
                      "Expects assert handler was called on accessing SwiftLintFile.syntaxKindsByLines")

        assertHandlerCalled = false
        _ = file.sourceKitSyntaxTokensByLines
        XCTAssertTrue(assertHandlerCalled,
                      "Expects assert handler was not called on accessing SwiftLintFile.syntaxTokensByLines")
    }

    func testRulesWithFileThatCrashedSourceKitService() throws {
        let file = try XCTUnwrap(SwiftLintFile(path: "\(TestResources.path)/ProjectMock/Level0.swift"))
        file.sourcekitdFailed = true
        file.assertHandler = {
            XCTFail("If this called, rule's SourceKitFreeRule is not properly configured")
        }
        let configuration = Configuration(rulesMode: .only(allRuleIdentifiers))
        let storage = RuleStorage()
        _ = Linter(file: file, configuration: configuration).collect(into: storage).styleViolations(using: storage)
        file.sourcekitdFailed = false
        file.assertHandler = nil
    }
}
