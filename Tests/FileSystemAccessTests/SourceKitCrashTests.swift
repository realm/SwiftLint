import TestHelpers
import XCTest

@testable import SwiftLintFramework

final class SourceKitCrashTests: SwiftLintTestCase {
    override func invokeTest() {
        CurrentRule.$allowSourceKitRequestWithoutRule.withValue(true) {
            super.invokeTest()
        }
    }

    func testAssertHandlerIsNotCalledOnNormalFile() {
        let file = SwiftLintFile(contents: "A file didn't crash SourceKitService")
        file.sourcekitdFailed = false

        var assertHandlerCalled = false
        file.assertHandler = { assertHandlerCalled = true }

        _ = file.syntaxMap
        XCTAssertFalse(assertHandlerCalled,
                       "Expects assert handler was not called on accessing SwiftLintFile.syntaxMap")
    }

    func testAssertHandlerIsCalledOnFileThatCrashedSourceKitService() {
        let file = SwiftLintFile(contents: "A file crashed SourceKitService")
        file.sourcekitdFailed = true

        var assertHandlerCalled = false
        file.assertHandler = { assertHandlerCalled = true }

        _ = file.syntaxMap
        XCTAssertTrue(assertHandlerCalled,
                      "Expects assert handler was called on accessing SwiftLintFile.syntaxMap")
    }

    func testRulesWithFileThatCrashedSourceKitService() throws {
        let path = TestResources.path()
            .appendingPathComponent("ProjectMock")
            .appendingPathComponent("Level0.swift")
        let file = try XCTUnwrap(SwiftLintFile(path: path))
        file.sourcekitdFailed = true
        file.assertHandler = {
            XCTFail("If this called, rule's SourceKitFreeRule is not properly configured")
        }
        let configuration = Configuration(rulesMode: .onlyConfiguration(allRuleIdentifiers))
        let storage = RuleStorage()
        _ = Linter(file: file, configuration: configuration).collect(into: storage).styleViolations(using: storage)
        file.sourcekitdFailed = false
        file.assertHandler = nil
    }
}
