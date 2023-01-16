@_spi(TestHelper)
@testable import SwiftLintFramework
import SwiftLintTestHelpers
import XCTest

class SourceKitCrashTests: XCTestCase {
    func testAssertHandlerIsNotCalledOnNormalFile() {
        let file = SwiftLintFile(contents: "A file didn't crash SourceKitService")
        file.sourcekitdFailed = false

        var assertHandlerCalled = false
        file.assertHandler = { assertHandlerCalled = true }

        _ = file.syntaxMap
        XCTAssertFalse(assertHandlerCalled,
                       "Expects assert handler was not called on accessing SwiftLintFile.syntaxMap")

        assertHandlerCalled = false
        _ = file.syntaxKindsByLines
        XCTAssertFalse(assertHandlerCalled,
                       "Expects assert handler was not called on accessing SwiftLintFile.syntaxKindsByLines")

        assertHandlerCalled = false
        _ = file.syntaxTokensByLines
        XCTAssertFalse(assertHandlerCalled,
                       "Expects assert handler was not called on accessing SwiftLintFile.syntaxTokensByLines")
    }

    func testAssertHandlerIsCalledOnFileThatCrashedSourceKitService() {
        let file = SwiftLintFile(contents: "A file crashed SourceKitService")
        file.sourcekitdFailed = true

        var assertHandlerCalled = false
        file.assertHandler = { assertHandlerCalled = true }

        _ = file.syntaxMap
        XCTAssertTrue(assertHandlerCalled,
                      "Expects assert handler was called on accessing SwiftLintFile.syntaxMap")

        assertHandlerCalled = false
        _ = file.syntaxKindsByLines
        XCTAssertTrue(assertHandlerCalled,
                      "Expects assert handler was called on accessing SwiftLintFile.syntaxKindsByLines")

        assertHandlerCalled = false
        _ = file.syntaxTokensByLines
        XCTAssertTrue(assertHandlerCalled,
                      "Expects assert handler was not called on accessing SwiftLintFile.syntaxTokensByLines")
    }

    func testRulesWithFileThatCrashedSourceKitService() throws {
        try XCTSkipIf(shouldSkipRulesXcodeprojRunFiles)

        let file = SwiftLintFile(path: #file)!
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
