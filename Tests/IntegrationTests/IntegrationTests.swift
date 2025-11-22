import Foundation
import SourceKittenFramework
import SwiftLintCore
import SwiftLintFramework
import TestHelpers
import XCTest

private let config: Configuration = {
    let bazelWorkspaceDirectory = ProcessInfo.processInfo.environment["BUILD_WORKSPACE_DIRECTORY"]
    let rootProjectDirectory = bazelWorkspaceDirectory ?? #filePath.bridge()
        .deletingLastPathComponent.bridge()
        .deletingLastPathComponent.bridge()
        .deletingLastPathComponent
    _ = FileManager.default.changeCurrentDirectoryPath(rootProjectDirectory)
    return Configuration(configurationFiles: [Configuration.defaultFileName])
}()

final class IntegrationTests: SwiftLintTestCase {
    func testSwiftLintLints() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["SKIP_INTEGRATION_TESTS"] == nil,
            "Will be covered by separate linting job"
        )
        // This is as close as we're ever going to get to a self-hosting linter.
        let swiftFiles = config.lintableFiles(
            inPath: "",
            forceExclude: false,
            excludeByPrefix: false)
        XCTAssert(
            swiftFiles.contains(where: { #filePath.bridge().absolutePathRepresentation() == $0.path }),
            "current file should be included"
        )

        let storage = RuleStorage()
        let violations = swiftFiles.parallelFlatMap {
            Linter(file: $0, configuration: config).collect(into: storage).styleViolations(using: storage)
        }
        violations.forEach { violation in
            violation.location.file!.withStaticString {
                XCTFail(violation.reason, file: $0, line: UInt(violation.location.line!))
            }
        }
    }

    func testSwiftLintAutoCorrects() throws {
        try XCTSkipUnless(
            ProcessInfo.processInfo.environment["SKIP_INTEGRATION_TESTS"] == nil,
            "Corrections are not verified in CI"
        )
        let swiftFiles = config.lintableFiles(
            inPath: "",
            forceExclude: false,
            excludeByPrefix: false)
        let storage = RuleStorage()
        let corrections = swiftFiles.parallelMap {
            Linter(file: $0, configuration: config).collect(into: storage).correct(using: storage)
        }
        XCTAssert(corrections.allSatisfy(\.isEmpty), "Unexpected corrections have been applied")
    }
}
