import Foundation
import TestHelpers
import Testing

@testable import SwiftLintFramework

extension FileSystemAccessTestSuite.SourceKitCrashTests {
    @Test(.sourceKitRequestsWithoutRule)
    @TemporaryDirectory
    func assertHandlerIsNotCalledOnNormalFile() {
        let file = SwiftLintFile(contents: "A file didn't crash SourceKitService")
        file.sourcekitdFailed = false

        var assertHandlerCalled = false
        file.assertHandler = { assertHandlerCalled = true }

        _ = file.syntaxMap
        #expect(!assertHandlerCalled, "Expects assert handler was not called on accessing SwiftLintFile.syntaxMap")
    }

    @Test(.sourceKitRequestsWithoutRule)
    @TemporaryDirectory
    func assertHandlerIsCalledOnFileThatCrashedSourceKitService() {
        let file = SwiftLintFile(contents: "A file crashed SourceKitService")
        file.sourcekitdFailed = true

        var assertHandlerCalled = false
        file.assertHandler = { assertHandlerCalled = true }

        _ = file.syntaxMap
        #expect(assertHandlerCalled, "Expects assert handler was called on accessing SwiftLintFile.syntaxMap")
    }

    @Test(.sourceKitRequestsWithoutRule)
    @WorkingDirectory(path: Constants.Dir.level0)
    func rulesWithFileThatCrashedSourceKitService() throws {
        let file = try #require(SwiftLintFile(path: "Level0.swift"))
        file.sourcekitdFailed = true
        file.assertHandler = {
            Issue.record("If this called, rule's SourceKitFreeRule is not properly configured")
        }
        let configuration = Configuration(rulesMode: .onlyConfiguration(allRuleIdentifiers))
        let storage = RuleStorage()
        _ = Linter(file: file, configuration: configuration).collect(into: storage).styleViolations(using: storage)
        file.sourcekitdFailed = false
        file.assertHandler = nil
    }
}
