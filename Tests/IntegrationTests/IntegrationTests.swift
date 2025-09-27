import Foundation
import SwiftLintFramework
import TestHelpers
import Testing

private let config: Configuration = {
    let bazelWorkspaceDirectory = ProcessInfo.processInfo.environment["BUILD_WORKSPACE_DIRECTORY"]
    let rootProjectDirectory = bazelWorkspaceDirectory ?? #filePath.bridge()
        .deletingLastPathComponent.bridge()
        .deletingLastPathComponent.bridge()
        .deletingLastPathComponent
    _ = FileManager.default.changeCurrentDirectoryPath(rootProjectDirectory)
    return Configuration(configurationFiles: [Configuration.defaultFileName])
}()

@Suite(.rulesRegistered)
struct IntegrationTests {
    @Test(.enabled(
        if: ProcessInfo.processInfo.environment["SKIP_INTEGRATION_TESTS"] == nil,
        "Will be covered by separate linting job"
    ))
    func lint() throws {
        // This is as close as we're ever going to get to a self-hosting linter.
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
            #expect(
                Bool(false),
                Comment(rawValue: violation.reason),
                sourceLocation: SourceLocation(
                    fileID: #fileID,
                    filePath: violation.location.file!,
                    line: Int(violation.location.line!),
                    column: Int(violation.location.character!)
                )
            )
        }
    }

    @Test(.enabled(
        if: ProcessInfo.processInfo.environment["SKIP_INTEGRATION_TESTS"] == nil,
        "Corrections are not verified in CI"
    ))
    func correct() throws {
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
