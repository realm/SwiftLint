import Foundation
import SourceKittenFramework
@_spi(TestHelper)
@testable import SwiftLintFramework
import XCTest

class DisabledRulesForFileTest: XCTestCase {
    private var previousWorkingDir: String!

    private func getTestLogicFile() -> SwiftLintFile {
        return SwiftLintFile(path: "\(testResourcesPath)/ProjectMock/IntentionalViolations/TooManyParameters.swift")!
    }

    func testExcludesUseCaseErrorFile() {
        let logicFile = getTestLogicFile()

        let storage = RuleStorage()
        let violations = Linter(
            file: logicFile,
            configuration: .init(
                configurationFiles: ["\(testResourcesPath)/ProjectMock/disabled_rules_for_files.yml"]
            )
        ).collect(into: storage).styleViolations(using: storage)
        XCTAssertEqual(violations.count, 0)
    }

    func testFindsUseCaseError() {
        let logicFile = getTestLogicFile()

        let storage = RuleStorage()
        let violations = Linter(
            file: logicFile,
            configuration: .init()
        ).collect(into: storage).styleViolations(using: storage)
        XCTAssertEqual(violations.count, 1)
    }
}
