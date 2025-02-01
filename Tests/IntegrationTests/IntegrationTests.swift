import Foundation
import SourceKittenFramework
import SwiftLintCore
import SwiftLintFramework
import TestHelpers
import Testing

private let bazelWorkspaceDirectory = ProcessInfo.processInfo.environment["BUILD_WORKSPACE_DIRECTORY"]
private let rootProjectDirectory = bazelWorkspaceDirectory?.url() ?? #filePath.bridge()
    .deletingLastPathComponent.bridge()
    .deletingLastPathComponent.bridge()
    .deletingLastPathComponent
    .url()

@Suite(.rulesRegistered, .serialized)
struct IntegrationTests {
    @Test(.enabled(
        if: ProcessInfo.processInfo.environment["SKIP_INTEGRATION_TESTS"] == nil,
        "Will be covered by separate linting job"
    ))
    @WorkingDirectory(path: rootProjectDirectory)
    func lint() throws {
        // This is as close as we're ever going to get to a self-hosting linter.
        let config = Configuration(configurationFiles: [Configuration.defaultFileName.url()])
        let swiftFiles = config.lintableFiles(
            inPath: URL.cwd,
            forceExclude: false,
            excludeByPrefix: false)
        try #require(
            swiftFiles.contains(where: { $0.path?.filepath.hasSuffix(#filePath) == true }),
            "current file should be included"
        )

        let storage = RuleStorage()
        let violations = swiftFiles.parallelFlatMap {
            Linter(file: $0, configuration: config).collect(into: storage).styleViolations(using: storage)
        }
        for violation in violations {
            Issue.record(
                Comment(rawValue: violation.reason),
                sourceLocation: SourceLocation(
                    fileID: #fileID,
                    filePath: violation.location.file!.filepath,
                    line: violation.location.line ?? 1,
                    column: violation.location.character ?? 1
                )
            )
        }
    }

    @Test(.enabled(
        if: ProcessInfo.processInfo.environment["SKIP_INTEGRATION_TESTS"] == nil,
        "Corrections are not verified in CI"
    ))
    @WorkingDirectory(path: rootProjectDirectory)
    func correct() throws {
        let config = Configuration(configurationFiles: [Configuration.defaultFileName.url()])
        let swiftFiles = config.lintableFiles(
            inPath: URL.cwd,
            forceExclude: false,
            excludeByPrefix: false)
        let storage = RuleStorage()
        let corrections = swiftFiles.parallelMap {
            Linter(file: $0, configuration: config).collect(into: storage).correct(using: storage)
        }
        let noCorrectionsApplied = corrections.allSatisfy(\.isEmpty)
        try #require(noCorrectionsApplied, "Unexpected corrections have been applied")
    }
}
