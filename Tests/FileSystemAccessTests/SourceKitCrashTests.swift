import Foundation
import SourceKittenFramework
import SwiftLintCore
import TestHelpers
import Testing

@testable import SwiftLintFramework

@Suite(.rulesRegistered)
struct SourceKitCrashTests {
    @Test(.sourceKitRequestsWithoutRule)
    func sourceKitUnavailableShortCircuitsWithoutIssuingRequest() {
        // Regression test for the Swift Testing hang (PR #6048): when sourcekitd is unavailable,
        // SourceKit requests must fail fast instead of blocking on sourcekitd, which would starve
        // the bounded test executor and hang the run. The "unavailable" state is forced for this
        // task tree only, so tests running in parallel are unaffected.
        SourceKitStatus.$forceUnavailableForTesting.withValue(true) {
            // The central choke point used by every SourceKit-based rule (editorOpen, index,
            // cursorInfo) throws immediately rather than contacting sourcekitd, so no request is
            // issued.
            #expect(throws: SourceKitUnavailableError.self) {
                try Request.editorOpen(file: SwiftLintFile(contents: "struct Foo {}").file).sendIfNotDisabled()
            }
            // And a file consequently reports the failure without blocking on a request.
            let file = SwiftLintFile(contents: "struct Foo {}")
            #expect(file.sourcekitdFailed)
        }
    }

    @Test(.sourceKitRequestsWithoutRule)
    func assertHandlerIsNotCalledOnNormalFile() {
        let file = SwiftLintFile(contents: "A file didn't crash SourceKitService")
        file.sourcekitdFailed = false

        var assertHandlerCalled = false
        file.assertHandler = { assertHandlerCalled = true }

        _ = file.syntaxMap
        #expect(!assertHandlerCalled, "Expects assert handler was not called on accessing SwiftLintFile.syntaxMap")
    }

    @Test(.sourceKitRequestsWithoutRule)
    func assertHandlerIsCalledOnFileThatCrashedSourceKitService() {
        let file = SwiftLintFile(contents: "A file crashed SourceKitService")
        file.sourcekitdFailed = true

        var assertHandlerCalled = false
        file.assertHandler = { assertHandlerCalled = true }

        _ = file.syntaxMap
        #expect(assertHandlerCalled, "Expects assert handler was called on accessing SwiftLintFile.syntaxMap")
    }

    @Test(.sourceKitRequestsWithoutRule, .workingDirectory(Constants.Dir.level0))
    func rulesWithFileThatCrashedSourceKitService() throws {
        let file = try #require(SwiftLintFile(path: "Level0.swift".url()))
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
