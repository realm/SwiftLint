import Foundation
import SwiftLintFramework
import TestHelpers
import Testing

private let bazelWorkspaceDirectory = ProcessInfo.processInfo.environment["BUILD_WORKSPACE_DIRECTORY"]
private let rootProjectDirectory = bazelWorkspaceDirectory ?? #filePath.bridge()
    .deletingLastPathComponent.bridge()
    .deletingLastPathComponent.bridge()
    .deletingLastPathComponent

@Suite(.rulesRegistered)
struct IntegrationTests {
    @Test(.enabled(
        if: ProcessInfo.processInfo.environment["SKIP_INTEGRATION_TESTS"] == nil,
        "Will be covered by separate linting job"
    ))
    @WorkingDirectory(path: rootProjectDirectory)
    func lint() throws {
        // This is as close as we're ever going to get to a self-hosting linter.
        let config = Configuration(configurationFiles: [Configuration.defaultFileName])
        let swiftFiles = config.lintableFiles(
            inPath: "",
            forceExclude: false,
            excludeBy: .paths(excludedPaths: config.excludedPaths()))
        try #require(
            swiftFiles.contains(where: { #filePath.bridge().absolutePathRepresentation() == $0.path }),
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
                    filePath: violation.location.file!,
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
        let config = Configuration(configurationFiles: [Configuration.defaultFileName])
        let swiftFiles = config.lintableFiles(
            inPath: "",
            forceExclude: false,
            excludeBy: .paths(excludedPaths: config.excludedPaths()))
        let storage = RuleStorage()
        let corrections = swiftFiles.parallelMap {
            Linter(file: $0, configuration: config).collect(into: storage).correct(using: storage)
        }
        try #require(corrections.allSatisfy { $0.isEmpty }, "Unexpected corrections have been applied")
    }
}
